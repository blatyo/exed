#[macro_use]
extern crate rustler;
#[macro_use]
extern crate rustler_codegen;
//#[macro_use] extern crate lazy_static;

mod exed_command;

use exed_command::ExedCommand;
use rustler::{Encoder, Env, Error, Term};

mod atoms {
    rustler_atoms! {
        atom ok;
        //atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

rustler_export_nifs! {
    "Elixir.Exed.Native.Command",
    [("to_string", 1, to_string)],
    None
}

fn to_string<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let ex_cmd: ExedCommand = args[0].decode()?;
    let cmd = ex_cmd.to_command();

    Ok(format!("{:#?}", cmd).encode(env))
}

