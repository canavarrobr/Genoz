// Tipos internos dos pacotes de anotação abertos, fora de `api` para não virarem
// parte da ponte (o gerador expõe traits e tipos que encontra em `api`).

use std::io::{Cursor, Read, Seek};

use genoz_core::annotation::{AnnotRecord, AnnotationPackage};
use serde::{Deserialize, Serialize};

pub(crate) enum Open {
    Disk(AnnotationPackage<std::io::BufReader<std::fs::File>>),
    Memory(AnnotationPackage<Cursor<Vec<u8>>>),
}

impl Open {
    pub(crate) fn with<T>(&mut self, f: impl FnOnce(&mut dyn PackageOps) -> T) -> T {
        match self {
            Open::Disk(p) => f(p),
            Open::Memory(p) => f(p),
        }
    }
}

pub(crate) trait PackageOps {
    fn id(&self) -> String;
    fn annotate(&mut self, chrom: &str, pos: u64, r: &str, a: &str) -> genoz_core::Result<Vec<AnnotRecord>>;
    fn find_name(&mut self, name: &str) -> genoz_core::Result<Vec<AnnotRecord>>;
}

impl<R: Read + Seek> PackageOps for AnnotationPackage<R> {
    fn id(&self) -> String {
        self.manifest.id.clone()
    }
    fn annotate(&mut self, chrom: &str, pos: u64, r: &str, a: &str) -> genoz_core::Result<Vec<AnnotRecord>> {
        AnnotationPackage::annotate(self, chrom, pos, r, a)
    }
    fn find_name(&mut self, name: &str) -> genoz_core::Result<Vec<AnnotRecord>> {
        AnnotationPackage::find_name(self, name)
    }
}

/// Metadados vindos do app (do catálogo ou do formulário do pacote próprio).
#[derive(Deserialize, Default)]
#[serde(default)]
pub(crate) struct MetaIn {
    pub(crate) id: String,
    pub(crate) name: String,
    pub(crate) build: String,
    pub(crate) source: String,
    pub(crate) source_url: String,
    pub(crate) version: String,
    pub(crate) date: String,
    pub(crate) license: String,
    pub(crate) license_url: String,
    pub(crate) citation: String,
    pub(crate) disclaimer: String,
}

#[derive(Deserialize)]
pub(crate) struct RowIn {
    pub(crate) chrom: String,
    pub(crate) pos: u64,
    #[serde(rename = "ref")]
    pub(crate) reference: String,
    pub(crate) alt: String,
}

#[derive(Serialize)]
pub(crate) struct RecordOut {
    pub(crate) chrom: String,
    pub(crate) start: u64,
    pub(crate) end: u64,
    #[serde(rename = "ref")]
    pub(crate) reference: String,
    pub(crate) alt: String,
    pub(crate) name: String,
    pub(crate) fields: Vec<String>,
}

impl From<AnnotRecord> for RecordOut {
    fn from(r: AnnotRecord) -> Self {
        Self { chrom: r.chrom, start: r.start, end: r.end, reference: r.reference, alt: r.alt, name: r.name, fields: r.fields }
    }
}

#[derive(Serialize)]
pub(crate) struct Hit {
    pub(crate) package: String,
    pub(crate) records: Vec<RecordOut>,
}
