#![feature(uefi_std, never_type)]
use std::os::uefi as uefi_std;
use std::sync::atomic::{AtomicBool, Ordering};

use thiserror::Error;
use uefi::runtime::ResetType;
use uefi::{Handle, Status};

/// A flag to check if the UEFI environment has been initialized. This is used
/// to prevent the UEFI environment from being initialized multiple times and
/// to prevent access to the UEFI environment before it has been initialized.
static INITIALIZED: AtomicBool = AtomicBool::new(false);

#[derive(Error, Debug)]
enum InitializationError {}

/// Runs the required setup for the UEFI crate. This function will panic if the
/// UEFI environment has already been initialized.
fn setup_uefi() {
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

fn main() -> Result<!, InitializationError> {
    setup_uefi();
    println!("UEFI-Version is {}", uefi::system::uefi_revision());
    uefi::runtime::reset(ResetType::SHUTDOWN, Status::SUCCESS, None);
}
