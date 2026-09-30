//! Escrita de VCF (texto ou BGZF).

use std::io::Write;

use crate::header::VcfHeader;
use crate::record::Record;
use crate::Result;

pub fn write_header<W: Write + ?Sized>(w: &mut W, header: &VcfHeader, extra_meta: &[String]) -> Result<()> {
    for line in &header.meta_lines {
        writeln!(w, "{line}")?;
    }
    for line in extra_meta {
        writeln!(w, "{line}")?;
    }
    writeln!(w, "{}", header.column_line())?;
    Ok(())
}

pub fn write_record<W: Write + ?Sized>(w: &mut W, rec: &Record) -> Result<()> {
    writeln!(w, "{}", rec.to_vcf_line())?;
    Ok(())
}
