use gdnative::api::OS;
use gdnative::prelude::*;

fn init(handle: InitHandle) {
    handle.add_class::<Pinger>();
}

godot_init!(init);

#[derive(NativeClass)]
#[inherit(Reference)]
struct Pinger;

#[methods]
impl Pinger {
    fn new(_: &Reference) -> Self {
        Pinger
    }

    #[export]
    fn ping(&self, _: &Reference) -> String {
        "hello".to_string()
    }

    #[export]
    fn add_int(&self, _: &Reference, a: i32, b: i32) -> i32 {
        a + b
    }

    #[export]
    fn count_up_msec(&self, _: &Reference) -> i64 {
        let os = OS::godot_singleton();

        os.get_ticks_msec()
    }
}
