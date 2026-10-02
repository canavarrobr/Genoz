//! Núcleo bioinformático do Genoz.
//!
//! Regras (ver `docs/especificacao`):
//! - toda lógica científica fica aqui; a interface (Flutter) só orquestra;
//! - processamento em streaming: a memória não cresce com o tamanho do arquivo;
//! - nenhum acesso à rede; genótipos nunca vão para logs;
//! - mesma entrada → mesma saída, em qualquer plataforma (nativo ou WASM).
//!
//! As funções trabalham sobre `std::io::Read`, e não sobre caminhos, para que o
//! mesmo código rode no navegador (WASM), no celular e no PC.

pub mod annotation;
pub mod build;
pub mod call;
pub mod chip_compare;
pub mod chrom;
pub mod compare;
pub mod consumer;
pub mod density;
pub mod digest;
pub mod error;
pub mod family;
pub mod fasta;
pub mod fields;
pub mod filter;
pub mod header;
pub mod inspect;
pub mod io;
pub mod manifest;
pub mod normalize;
pub mod pack;
pub mod pdf;
pub mod reader;
pub mod record;
pub mod regions;
pub mod report;
pub mod results;
pub mod stats;
pub mod synth;
pub mod vault;
pub mod writer;

pub use error::{GenozError, Result};

/// Versão do núcleo, registrada nos manifestos de reprodutibilidade.
pub const CORE_VERSION: &str = env!("CARGO_PKG_VERSION");
