#[macro_use] extern crate rustler;
#[macro_use] extern crate rustler_codegen;
//#[macro_use] extern crate lazy_static;

use std::process::Command;
use std::collections::HashMap;
use rustler::{Env, Error, Term, Encoder, Decoder, NifResult};
use rustler::types::MapIterator;

mod atoms {
    rustler_atoms! {
        atom ok;
        //atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

struct Envs {
    pub map: HashMap<String, String>,
}

impl<'a> Decoder<'a> for Envs {
    fn decode(term: Term<'a>) -> NifResult<Self> {
        match MapIterator::new(term) {
            Some(iter) => {
                let map: HashMap<String, String> = HashMap::new();
                let mut envs = Envs{map};
                for (key_term, value_term) in iter {
                    let key: String = key_term.decode().ok().unwrap();
                    let value: String = value_term.decode().ok().unwrap();
                    envs.map.insert(key, value);
                }
                Ok(envs)
            }
            None => Err(Error::BadArg),
        }
    }
}

impl Encoder for Envs {
    fn encode<'b>(&self, env: Env<'b>) -> Term<'b> {
        self.map.iter().fold(Term::map_new(env), |map, (key, value)| {
            Term::map_put(map, key.encode(env), value.encode(env)).ok().unwrap()
        })
    }
}

#[derive(NifStruct)]
#[module = "Exed.Native.Command"]
struct ExedCommand {
    pub binary: String,
    pub args: Vec<String>,
    pub envs: Envs,
    pub current_dir: Option<String>,
}

rustler_export_nifs! {
    "Elixir.Exed.Native.Command",
    [("to_string", 1, to_string)],
    None
}

fn to_string<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let ex_cmd: ExedCommand = args[0].decode()?;
    let cmd = to_command(ex_cmd);

    Ok(format!("{:#?}", cmd).encode(env))
}

fn to_command(ex_cmd: ExedCommand) -> Command {
    let mut cmd = Command::new(ex_cmd.binary);

    cmd.envs(ex_cmd.envs.map.iter());

    for arg in ex_cmd.args.iter() {
        cmd.arg(arg);
    }

    if let Some(current_dir) = ex_cmd.current_dir {
        cmd.current_dir(current_dir);
    }

    cmd
}
