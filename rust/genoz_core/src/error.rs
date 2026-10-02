use thiserror::Error;

/// Erros fatais: impedem continuar a leitura do arquivo.
///
/// Problemas em linhas individuais não são `GenozError`; eles viram
/// [`crate::reader::Issue`] no relatório de validação.
#[derive(Debug, Error)]
pub enum GenozError {
    #[error("falha de leitura: {0}")]
    Io(#[from] std::io::Error),

    #[error("cabeçalho VCF inválido: {0}")]
    InvalidHeader(String),

    #[error("parâmetro inválido: {0}")]
    InvalidParam(String),
}

pub type Result<T> = std::result::Result<T, GenozError>;

impl GenozError {
    /// Mensagem curta em português para mostrar ao usuário.
    pub fn user_message(&self) -> String {
        match self {
            GenozError::Io(e) if crate::vault::is_auth_error(e) => e.to_string(),
            GenozError::Io(e) => match e.kind() {
                std::io::ErrorKind::NotFound => "arquivo não encontrado".into(),
                std::io::ErrorKind::PermissionDenied => "sem permissão para ler o arquivo".into(),
                std::io::ErrorKind::UnexpectedEof => {
                    "o arquivo terminou antes do esperado (download incompleto ou arquivo truncado)".into()
                }
                std::io::ErrorKind::InvalidInput | std::io::ErrorKind::InvalidData => {
                    format!("arquivo compactado corrompido ou em formato inesperado ({e})")
                }
                _ => format!("falha de leitura ({e})"),
            },
            other => other.to_string(),
        }
    }
}
