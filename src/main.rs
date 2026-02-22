use ib_matcher::{
    matcher::{IbMatcher, PinyinMatchConfig},
    pinyin::PinyinNotation,
};
use std::env;
use std::io::{BufRead, BufReader};

fn is_pure_english_path(s: &str) -> bool {
    // Consider a path "pure English" if every character is within a conservative
    // ASCII set that zsh already handles well: letters, digits, '_', '-', '.', '/', '~'.
    // We also ignore trailing newlines/spaces (already trimmed).
    // Require at least one ASCII alphabetic letter so an empty string or just symbols
    // doesn't get suppressed accidentally.
    let mut has_alpha = false;
    for ch in s.chars() {
        if ch.is_ascii_alphabetic() {
            has_alpha = true;
            continue;
        }
        if ch.is_ascii_digit() || matches!(ch, '_' | '-' | '.' | '/' | '~') {
            continue;
        }
        // Any other (non ASCII or other punctuation) means it's not pure English.
        return false;
    }
    has_alpha
}

fn parse_pinyin_notation_env() -> PinyinNotation {
    // Use ZSH_PINYIN_NOTATION for zsh plugin (with fallback to PINYIN_COMP_MODE for compatibility)
    let env_val = env::var("ZSH_PINYIN_NOTATION")
        .or_else(|_| env::var("PINYIN_COMP_MODE"))
        .unwrap_or_default();
    let mut notation = PinyinNotation::empty();
    let mut shuangpin = Option::<PinyinNotation>::None;
    let mut has_quanpin = false;

    for mode in env_val.split(',') {
        let mode = mode.trim();
        match mode {
            "quanpin" | "Quanpin" => {
                notation |= PinyinNotation::Ascii;
                has_quanpin = true;
            }
            "abc" | "ShuangpinAbc" => {
                shuangpin.get_or_insert(PinyinNotation::DiletterAbc);
            }
            "jiajia" | "ShuangpinJiajia" => {
                shuangpin.get_or_insert(PinyinNotation::DiletterJiajia);
            }
            "ms" | "microsoft" | "ShuangpinMicrosoft" => {
                shuangpin.get_or_insert(PinyinNotation::DiletterMicrosoft);
            }
            "thunisoft" | "ShuangpinThunisoft" => {
                shuangpin.get_or_insert(PinyinNotation::DiletterThunisoft);
            }
            "xiaohe" | "ShuangpinXiaohe" => {
                shuangpin.get_or_insert(PinyinNotation::DiletterXiaohe);
            }
            "zrm" | "ShuangpinZrm" => {
                shuangpin.get_or_insert(PinyinNotation::DiletterZrm);
            }
            _ => {}
        }
    }

    notation |= shuangpin.unwrap_or(PinyinNotation::empty());

    if notation.is_empty() {
        notation = PinyinNotation::Ascii;
    }

    // Always enable first letter matching when quanpin is enabled
    // This allows single letter like 'x' to match '下' (xia), 'z' to match '桌' (zhuo)
    if has_quanpin || notation == PinyinNotation::Ascii {
        notation |= PinyinNotation::AsciiFirstLetter;
    }

    notation
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    // Print usage
    if args.len() < 2 {
        eprintln!("Usage: {} <pinyin>", args[0]);
        eprintln!("\nReads candidate paths from stdin, outputs matching paths.");
        eprintln!("\nPinyin notation is controlled by ZSH_PINYIN_NOTATION env var:");
        eprintln!("  quanpin    - Full pinyin (default)");
        eprintln!("  xiaohe     - Xiaohe shuangpin");
        eprintln!("  ms         - Microsoft shuangpin");
        eprintln!("  abc        - Intelligent ABC shuangpin");
        eprintln!("  jiajia     - Pinyin Jiajia shuangpin");
        eprintln!("  thunisoft  - Thunisoft shuangpin");
        eprintln!("  zrm        - Ziranma shuangpin");
        std::process::exit(1);
    }

    let input: &str = &args[1];
    let notation = parse_pinyin_notation_env();
    let pinyin_config = PinyinMatchConfig::builder(notation).build();

    let matcher = IbMatcher::builder(input)
        .starts_with(true)
        .pinyin(pinyin_config)
        .build();

    let stdin = std::io::stdin();
    let reader = BufReader::new(stdin.lock());
    for line_result in reader.lines() {
        let candidate = match line_result {
            Ok(line) => line.trim_end().to_string(),
            Err(_) => {
                continue;
            }
        };
        // For pure English paths, use simple prefix matching
        // For paths with Chinese characters, use pinyin matching
        if is_pure_english_path(&candidate) {
            // Simple prefix match for English paths
            if candidate.to_lowercase().starts_with(&input.to_lowercase()) {
                println!("{}", candidate);
            }
        } else if matcher.is_match(candidate.as_str()) {
            println!("{}", candidate);
        }
    }
}
