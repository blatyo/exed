use rustler::types::MapIterator;
use rustler::{Decoder, Encoder, Env, Error, NifResult, Term};
use std::collections::HashMap;
use std::collections::hash_map::Iter;
use std::process::Command;

#[derive(NifStruct)]
#[module = "Exed.Native.Command"]
pub struct ExedCommand {
    pub binary: String,
    pub args: Vec<String>,
    pub envs: Envs,
    pub current_dir: Option<String>,
}

impl ExedCommand {
  pub fn to_command(self) -> Command {
    let mut cmd = Command::new(self.binary);

    cmd.envs(self.envs.iter());

    for arg in self.args.iter() {
        cmd.arg(arg);
    }

    if let Some(current_dir) = self.current_dir {
        cmd.current_dir(current_dir);
    }

    cmd
  }
}

pub struct Envs {
    pub map: HashMap<String, String>,
}

impl Envs {
  pub fn iter(&self) -> Iter<'_, String, String> {
    self.map.iter()
  }

  pub fn insert(&mut self, k: String, v: String) -> Option<String> {
    self.map.insert(k, v)
  }
}

impl<'a> Decoder<'a> for Envs {
    fn decode(term: Term<'a>) -> NifResult<Self> {
        match MapIterator::new(term) {
            Some(iter) => {
                let map: HashMap<String, String> = HashMap::new();
                let mut envs = Envs { map };
                for (key_term, value_term) in iter {
                    let key: String = key_term.decode().ok().unwrap();
                    let value: String = value_term.decode().ok().unwrap();
                    envs.insert(key, value);
                }
                Ok(envs)
            }
            None => Err(Error::BadArg),
        }
    }
}

impl Encoder for Envs {
    fn encode<'b>(&self, env: Env<'b>) -> Term<'b> {
        self.iter()
            .fold(Term::map_new(env), |map, (key, value)| {
                Term::map_put(map, key.encode(env), value.encode(env))
                    .ok()
                    .unwrap()
            })
    }
}
