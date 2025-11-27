// TASK 8.1: Command Parser Module
// Жёсткий DSL парсер для агентских команд (INDEX / TRAIN / GIT)

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Типы поддерживаемых команд
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum CommandKind {
    IndexKnowledge,
    TrainAgent,
    GitPush,
}

/// Структура распарсенной команды
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParsedCommand {
    pub kind: CommandKind,
    pub args: HashMap<String, String>,
}

/// Ошибки парсинга
#[derive(Debug, Clone)]
pub enum ParseError {
    EmptyCommand,
    UnknownCommandType(String),
    InvalidFormat(String),
    MissingArgument(String),
}

impl std::fmt::Display for ParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            ParseError::EmptyCommand => write!(f, "Команда не может быть пустой"),
            ParseError::UnknownCommandType(cmd) => write!(f, "Неизвестный тип команды: {}", cmd),
            ParseError::InvalidFormat(msg) => write!(f, "Неверный формат: {}", msg),
            ParseError::MissingArgument(arg) => write!(f, "Отсутствует обязательный аргумент: {}", arg),
        }
    }
}

/// Парсинг команды из текстового формата
/// 
/// Формат:
/// ```
/// INDEX KNOWLEDGE
/// PATH="D:\PROJECTS\TRIZ_LOGS"
/// MODE="local"
/// PROFILE="triz_engineer"
/// ```
pub fn parse_command(text: &str) -> Result<ParsedCommand, ParseError> {
    let text = text.trim();
    
    if text.is_empty() {
        return Err(ParseError::EmptyCommand);
    }

    let lines: Vec<&str> = text.lines().map(|l| l.trim()).collect();
    
    if lines.is_empty() {
        return Err(ParseError::EmptyCommand);
    }

    // Парсим первую строку — тип команды
    let command_line = lines[0].to_uppercase();
    let kind = match command_line.as_str() {
        "INDEX KNOWLEDGE" => CommandKind::IndexKnowledge,
        "TRAIN AGENT" => CommandKind::TrainAgent,
        "GIT PUSH" => CommandKind::GitPush,
        _ => return Err(ParseError::UnknownCommandType(lines[0].to_string())),
    };

    // Парсим аргументы (все строки после первой)
    let mut args = HashMap::new();
    
    for (idx, line) in lines.iter().enumerate().skip(1) {
        if line.is_empty() {
            continue; // Пропускаем пустые строки
        }

        // Ожидаем формат: KEY="VALUE"
        if let Some(eq_pos) = line.find('=') {
            let key = line[..eq_pos].trim().to_string();
            let value_part = line[eq_pos + 1..].trim();

            // Проверяем, что значение в кавычках
            if value_part.starts_with('"') && value_part.ends_with('"') && value_part.len() >= 2 {
                let value = value_part[1..value_part.len() - 1].to_string();
                args.insert(key, value);
            } else {
                return Err(ParseError::InvalidFormat(
                    format!("Строка {}: значение должно быть в кавычках (KEY=\"VALUE\")", idx + 1)
                ));
            }
        } else {
            return Err(ParseError::InvalidFormat(
                format!("Строка {}: ожидается формат KEY=\"VALUE\"", idx + 1)
            ));
        }
    }

    Ok(ParsedCommand { kind, args })
}

/// Валидация команды INDEX KNOWLEDGE
pub fn validate_index_knowledge(cmd: &ParsedCommand) -> Result<(), ParseError> {
    if cmd.kind != CommandKind::IndexKnowledge {
        return Err(ParseError::InvalidFormat("Не INDEX KNOWLEDGE команда".to_string()));
    }

    // PATH обязателен
    if !cmd.args.contains_key("PATH") {
        return Err(ParseError::MissingArgument("PATH".to_string()));
    }

    // MODE необязателен, но если есть — проверяем допустимые значения
    if let Some(mode) = cmd.args.get("MODE") {
        let valid_modes = ["local", "global", "hybrid", "naive"];
        if !valid_modes.contains(&mode.as_str()) {
            return Err(ParseError::InvalidFormat(
                format!("MODE должен быть одним из: {:?}", valid_modes)
            ));
        }
    }

    Ok(())
}

/// Валидация команды TRAIN AGENT
pub fn validate_train_agent(cmd: &ParsedCommand) -> Result<(), ParseError> {
    if cmd.kind != CommandKind::TrainAgent {
        return Err(ParseError::InvalidFormat("Не TRAIN AGENT команда".to_string()));
    }

    // PROFILE обязателен
    if !cmd.args.contains_key("PROFILE") {
        return Err(ParseError::MissingArgument("PROFILE".to_string()));
    }

    // DATA_PATH обязателен
    if !cmd.args.contains_key("DATA_PATH") {
        return Err(ParseError::MissingArgument("DATA_PATH".to_string()));
    }

    // EPOCHS необязателен, но если есть — проверяем число
    if let Some(epochs_str) = cmd.args.get("EPOCHS") {
        if epochs_str.parse::<u32>().is_err() {
            return Err(ParseError::InvalidFormat(
                "EPOCHS должен быть целым числом".to_string()
            ));
        }
    }

    Ok(())
}

/// Валидация команды GIT PUSH
pub fn validate_git_push(cmd: &ParsedCommand) -> Result<(), ParseError> {
    if cmd.kind != CommandKind::GitPush {
        return Err(ParseError::InvalidFormat("Не GIT PUSH команда".to_string()));
    }

    // REPO_PATH обязателен
    if !cmd.args.contains_key("REPO_PATH") {
        return Err(ParseError::MissingArgument("REPO_PATH".to_string()));
    }

    // BRANCH необязателен
    // SUMMARY необязателен

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_index_knowledge() {
        let text = r#"INDEX KNOWLEDGE
PATH="D:\PROJECTS\TRIZ_LOGS"
MODE="local"
PROFILE="triz_engineer""#;

        let result = parse_command(text);
        assert!(result.is_ok());
        
        let cmd = result.unwrap();
        assert_eq!(cmd.kind, CommandKind::IndexKnowledge);
        assert_eq!(cmd.args.get("PATH"), Some(&"D:\\PROJECTS\\TRIZ_LOGS".to_string()));
        assert_eq!(cmd.args.get("MODE"), Some(&"local".to_string()));
        assert_eq!(cmd.args.get("PROFILE"), Some(&"triz_engineer".to_string()));
    }

    #[test]
    fn test_parse_train_agent() {
        let text = r#"TRAIN AGENT
PROFILE="triz_engineer"
DATA_PATH="D:\WORLD_OLLAMA\docs\cases"
EPOCHS="3"
MODE="llama_factory""#;

        let result = parse_command(text);
        assert!(result.is_ok());
        
        let cmd = result.unwrap();
        assert_eq!(cmd.kind, CommandKind::TrainAgent);
        assert_eq!(cmd.args.get("EPOCHS"), Some(&"3".to_string()));
    }

    #[test]
    fn test_parse_git_push() {
        let text = r#"GIT PUSH
REPO_PATH="E:\WORLD_OLLAMA"
BRANCH="feature/agent-updates"
SUMMARY="Agent auto-updates: configs, docs, specs""#;

        let result = parse_command(text);
        assert!(result.is_ok());
        
        let cmd = result.unwrap();
        assert_eq!(cmd.kind, CommandKind::GitPush);
    }

    #[test]
    fn test_invalid_format() {
        let text = "INDEX KNOWLEDGE\nPATH=invalid_no_quotes";
        let result = parse_command(text);
        assert!(result.is_err());
    }

    #[test]
    fn test_unknown_command() {
        let text = "UNKNOWN COMMAND\nKEY=\"VALUE\"";
        let result = parse_command(text);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_index_missing_path() {
        let cmd = ParsedCommand {
            kind: CommandKind::IndexKnowledge,
            args: HashMap::new(),
        };
        let result = validate_index_knowledge(&cmd);
        assert!(result.is_err());
    }
}
