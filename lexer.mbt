///|
fn is_space_code(code : Int) -> Bool {
  code == 32 || code == 9 || code == 10 || code == 13
}

///|
fn is_newline_code(code : Int) -> Bool {
  code == 10
}

///|
fn is_brace_code(code : Int) -> Bool {
  code == 123 || code == 125
}

///|
fn token_kind_for_brace(code : Int) -> BvhTokenKind {
  if code == 123 {
    TokenOpenBrace
  } else {
    TokenCloseBrace
  }
}

///|
fn token_text_for_brace(code : Int) -> String {
  if code == 123 {
    "{"
  } else {
    "}"
  }
}

///|
/// Split ASCII BVH source into words and braces while preserving token position.
pub fn tokenize_bvh(input : String) -> BvhTokenizeResult {
  if input.trim().length() == 0 {
    return BvhTokenizeResult::failure(
      BvhError::new(ErrorEmptyInput, "BVH source is empty"),
    )
  }
  let tokens : Array[BvhToken] = []
  let mut i = 0
  let mut line = 1
  let mut column = 1
  while i < input.length() {
    let code = input.unsafe_get(i).to_int()
    if is_space_code(code) {
      if is_newline_code(code) {
        line += 1
        column = 1
      } else {
        column += 1
      }
      i += 1
    } else if is_brace_code(code) {
      tokens.push(
        BvhToken::new(
          token_kind_for_brace(code),
          token_text_for_brace(code),
          line,
          column,
        ),
      )
      i += 1
      column += 1
    } else {
      let start = i
      let token_line = line
      let token_column = column
      while i < input.length() {
        let word_code = input.unsafe_get(i).to_int()
        if is_space_code(word_code) || is_brace_code(word_code) {
          break
        }
        i += 1
        column += 1
      }
      tokens.push(
        BvhToken::new(
          TokenWord,
          input[start:i].to_owned(),
          token_line,
          token_column,
        ),
      )
    }
  }
  BvhTokenizeResult::success(tokens)
}

///|
pub fn bvh_tokens_to_text(tokens : Array[BvhToken]) -> String {
  let parts : Array[String] = []
  for token in tokens {
    parts.push("\{token.text}@\{token.line}:\{token.column}")
  }
  parts.join(" ")
}
