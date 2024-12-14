#![feature(uefi_std, never_type)]
#![feature(custom_test_frameworks)]
#![test_runner(crate::test_runner::runner)]
#![reexport_test_harness_main = "test_main"]

use std::os::uefi as uefi_std;
use std::panic::{PanicHookInfo, set_hook as set_panic_hook};
use std::sync::atomic::{AtomicBool, Ordering};

use thiserror::Error;
use uefi::runtime::ResetType;
use uefi::{Handle, Status};

/// A flag to check if the UEFI environment has been initialized. This is used
/// to prevent the UEFI environment from being initialized multiple times and
/// to prevent access to the UEFI environment before it has been initialized.
static INITIALIZED: AtomicBool = AtomicBool::new(false);

#[cfg(test)]
mod test_runner;

#[derive(Error, Debug)]
enum InitializationError {}

/// Runs the required setup for the UEFI crate. This function will panic if the
/// UEFI environment has already been initialized.
pub(crate) fn setup_uefi() {
    // Check if the INITIALIZED flag is set and panic if it is.
    if INITIALIZED.swap(true, Ordering::AcqRel) {
        panic!("The UEFI environment has already been initialized.");
    }

    // SAFETY: The system table is guaranteed to be valid because it will panic
    // if the System Table is not initialized. We also checked that the
    // INITIALIZED flag is not set.
    unsafe {
        let system_table = uefi_std::env::system_table();
        uefi::table::set_system_table(system_table.as_ptr().cast());
    }

    // SAFETY: This is guaranteed to be valid because it will panic if the Image
    // Handle is not initialized. We also checked that the
    // INITIALIZED flag is not set.
    unsafe {
        let image_handle = uefi_std::env::image_handle();
        let ih = Handle::new(image_handle);
        uefi::boot::set_image_handle(ih);
    }
}

pub(crate) fn is_initialized() -> bool {
    INITIALIZED.load(Ordering::Acquire)
}

fn shutdown(status: Status) -> ! {
    uefi::runtime::reset(ResetType::SHUTDOWN, status, None);
}

fn panic_handler(panic_info: &PanicHookInfo) -> () {
    println!("{panic_info}");
    shutdown(Status::ABORTED);
}

fn main() -> Result<!, InitializationError> {
    setup_uefi();
    set_panic_hook(Box::new(panic_handler));

    println!("UEFI Version: {}", uefi::system::uefi_revision());

    #[cfg(test)]
    test_main();

    shutdown(Status::SUCCESS);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test_case]
    fn uefi_is_initialized() {
        assert!(is_initialized());
    }
}
