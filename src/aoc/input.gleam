import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type AocError {
  EnvError
  HttpError(String)
  FileError(simplifile.FileError)
}

const base_url = "https://adventofcode.com"

const user_agent = "github.com/anntnzrb/aoc25-gleam"

fn cache_path(year: Int, day: Int, ext: String) -> String {
  let day_str = int.to_string(day) |> string.pad_start(2, "0")
  "inputs/" <> int.to_string(year) <> "/day" <> day_str <> ext
}

fn parent_dir(path: String) -> String {
  let parts = string.split(path, "/")
  parts |> list.take(list.length(parts) - 1) |> string.join("/")
}

fn fetch_url(url: String, session: String) -> Result(String, AocError) {
  use req <- result.try(
    request.to(url) |> result.map_error(fn(_) { HttpError("Invalid URL") }),
  )

  req
  |> request.set_header("cookie", "session=" <> session)
  |> request.set_header("user-agent", user_agent)
  |> httpc.send
  |> result.map_error(fn(_) { HttpError("Request failed") })
  |> result.try(fn(resp) {
    case resp.status {
      200 -> Ok(resp.body)
      s -> Error(HttpError("HTTP " <> int.to_string(s)))
    }
  })
}

fn fetch_and_cache(
  url: String,
  path: String,
  session: String,
) -> Result(String, AocError) {
  case simplifile.read(path) {
    Ok(content) -> Ok(content)
    Error(_) -> {
      use content <- result.try(fetch_url(url, session))
      use _ <- result.try(
        simplifile.create_directory_all(parent_dir(path))
        |> result.map_error(FileError),
      )
      use _ <- result.try(
        simplifile.write(path, content) |> result.map_error(FileError),
      )
      Ok(content)
    }
  }
}

fn aoc_url(year: Int, day: Int, suffix: String) -> String {
  base_url
  <> "/"
  <> int.to_string(year)
  <> "/day/"
  <> int.to_string(day)
  <> suffix
}

pub fn get_input(
  year: Int,
  day: Int,
  session: String,
) -> Result(String, AocError) {
  fetch_and_cache(
    aoc_url(year, day, "/input"),
    cache_path(year, day, ".txt"),
    session,
  )
}

pub fn get_instructions(
  year: Int,
  day: Int,
  session: String,
) -> Result(String, AocError) {
  fetch_and_cache(
    aoc_url(year, day, ""),
    cache_path(year, day, ".html"),
    session,
  )
}
