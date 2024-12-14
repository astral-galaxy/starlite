use std::panic::set_hook as set_panic_hook;

use uefi::Status;

use crate::{panic_handler, setup_uefi, shutdown};

pub fn runner(tests: &[&dyn Fn()]) {
    setup_uefi();
    set_panic_hook(Box::new(panic_handler));

    println!("Running {} tests", tests.len());

    for test in tests {
        test();
    }
    println!("All tests passed");
    shutdown(Status::SUCCESS);
}
