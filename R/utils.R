#' generates a temporary file name
#' /tmp/HasHfolDER
tempfile_name <- function (){
    file.path (tempdir(), ".geoplumber.dat")
}

# currently just writes project directory to tempfile
write_tempfile <- function (dir_name){
    con <- file (tempfile_name())
    writeLines (dir_name, con)
    close (con)
}

#' returns the project name from the temp file
read_tempfile <- function (){
    if (!file.exists (tempfile_name()))
        stop ("No geoplumber project has been created")
    con <- file (tempfile_name())
    dir_name <- readLines (con)
    close (con)
    return (dir_name)
}

#' Useful function to find temp project name from
#' temporary file in /tmp/HasHfolDER/.geoplumber.dat
#' If that is not available (user could already be in a
#' geoplumber directory) then just returns current wd.
change_to_proj_dir <- function () {
  if (!(file.exists (tempfile_name ()) | file.exists ("package.json")))
    stop ("If project was built in a previous R session, you must ",
          "first manually change to project directory")

  wd <- getwd ()
  if (file.exists (tempfile_name ())) {
    project_dir <- read_tempfile ()
    if (!file.exists (project_dir))
      stop ("Project directory ", project_dir, " does not exist")
    wd <- setwd (project_dir)
  }
  return (wd)
}

#' takes a vector of strings, adds another vector
#' either before or after pattern provided.
#' @param target the vector to add what to
#' @param pattern where to add the what to
#' @param what vector to add to target
#' @param before or after the pattern
add_lines <- function (target, pattern, what, before = TRUE) {
  where.index <- grep(pattern, target)
  spaces <- next_spaces(target[where.index])
  if(before) {
    target <- c(target[1:where.index - 1],
                paste0(spaces, what),
                target[where.index:length(target)]
    )
  } else {
    target <- c(target[1:where.index],
                paste0(spaces, what),
                target[(where.index + 1):length(target)]
    )
  }
  target
}

#' takes a vector of strings, adds a Babel style import statement
#'
#' @param target vector to add import statement in.
#' @param component.name name of component to import.
#' @param component.path path to "import" from.
#' @param keyword to use as anchor to add import statement.
#' @param package is the import statement for a package?
#' TODO: multiple or `const {}` JS way of importing.
#'
add_import_component <- function(
  target,
  component.name,
  component.path,
  keyword = "export default",
  package = FALSE) {
  r <- target
  # Import new component
  # Above 'export default'
  export.index <- grep(keyword, target)
  # check for duplicate
  component.name.added <- grepl(paste0("import ", component.name), target)
  if(!any(component.name.added)) {
    # import GeoJSONComponent from '/components/GeoJSONComponent.jsx';
    # or
    # import Component from 'component' for npm packages
    line <- paste0("import ", component.name, " from './",
                   component.path, "';")
    if(package) {
      line <- paste0("import ", component.name, " from '",
                     component.path, "';")
    }
    r <- c(target[1:export.index - 1], line,
                 target[export.index:length(target)]
    )
  }
  r
}

#' Remove lines from a source file in place
#'
#' Utility function to remove lines from a source file
#'
#' @param path path of file to change, used in readLines()
#' @param pattern remove what, 1st is used. Unique is best.
#' @param lines_count 1 by default provide a number
#' @export
#' @examples \dontrun{
#'  gp_remove_lines()
#' }
gp_remove_lines <- function(path,
                            pattern = " * geoplumber R package code.",
                            lines_count = 1L
                            ) {
  con <- file(path, "r")
  v <- readLines(con)
  if(length(v) == 0 || lines_count < 1L) {
    stop("Empty file, ", path, "or wrong lines_count: ", lines_count, ".")
  }
  pattern.index <- grep(pattern = pattern, x = v)
  v <- c(
    v[1:(pattern.index - 1)], # to the line before pattern
    v[(pattern.index + lines_count):length(v)]
  )
  write(v, file = path)
  close(con)
}

#' Change a source file in place
#'
#' Utility function to make changes to a source file
#' @param path path of file to change, used in readLines()
#' @param what vector to add to path
#' @param pattern where to add the what to, 1st is used. Unique is best.
#' @param before s after the pattern
#' @param replace or replace pattern
#' @param verbose cat the change out
#' @export
#' @examples {
#'  gp_change_file(replace = TRUE, verbose = TRUE) # replacing the comment itself.
#' }
gp_change_file <- function(path = system.file("js/src/App.js", package = "geoplumber"),
                           what = " * geoplumber R package code.",
                           pattern = " * geoplumber R package code.",
                           before = TRUE,
                           replace = FALSE,
                           verbose= FALSE) {
  con <- file(path, "r")
  v <- readLines(con)
  if(length(v) == 0) {
    stop("Empty file, gp_change_file requires a file with min 1 line.")
  }
  # fail safe for default
  index <- grep(pattern, v)
  if(length(index) >= 1) {
    if(replace) {
      v <- c(v[1:index - 1], what, v[(index + 1):length(v)]
      )
    } else {
      v <- add_lines(target = v, pattern = pattern,
                     what = what, before = before)
    }
    if(verbose) {
      print(paste0("Changed at: ", index))
      print(v[index : (index + 5)])
    }
  } else {
    message("Pattern ", pattern, " not found.")
  }
  write(v, file = path)
  close(con)
}

next_spaces <- function(x, count = 4) {
  spaces <- regexpr("^\\s+", x)
  spaces <- attr(spaces, "match.length") # number of spaces of current line
  spaces <- rep(" ",  spaces + count)
  spaces <- paste(spaces, collapse = "")
  spaces
}

# checks if Rproj file exists in current working dir
rproj_file_exists <- function(path) {
  # TODO: sanity checks and +/-s
  files <- list.files(path = path)
  if(any(grepl(".Rproj", files))) {
    return(TRUE)
  }
  FALSE
}

#' Wrapper function to copy template.Rproj file into working directory.
#'
#' @param path project path to create .Rproj file in, defaults to ".".
#'
#' @export
#' @examples \dontrun{
#'  gp_rstudio()
#' }
gp_rstudio <- function(path = ".") {
  if (length(path) != 1L) # if and only if 1
    stop("'path' must be of length 1")
  if (is.na(path) || (path == "") || is.null(path))
    stop("A geoplumber app's path is required.")
  stopifnot(gp_is_wd_geoplumber(path))
  proj_name <- path
  if(identical(path, ".")) {
    proj_name <- basename(getwd())
  } else {
    proj_name <- basename(path)
  }
  if(rproj_file_exists(path))
    stop("There is a .Rproj file already")# already exists
  res <- file.copy(system.file("rproj_template", package = "geoplumber"),
            file.path(path, paste0(proj_name, ".Rproj")))
  return(res)
}

rename_package.json <- function(project_name) {
  if(!file.exists("package.json")) {
    stop(paste0("Error: working directory '", getwd(),
                "' does not include a package.json."))
  }
  pkg_json <- readLines("package.json")
  pkg_json[2] <- sub("geoplumber", project_name, pkg_json[2])
  # as it could be path or .
  write(pkg_json, "package.json") # project name reset.
}


#' Wrapper function to kill what is listening on a particular port.
#'
#' Detect sysytem and run command based on OS. This function supports
#' Linux, MacOS and Windows. There is no guarantee to kill the process.
#'
#' @param port targted port to kill process for defaults to `3000`
#'
#' @examples {
#' gp_kill_process()
#' }
#'
#' @export
gp_kill_process <- function(port = 3000) {
  stopifnot(exists("port"))
  # detect OS
  os <- get_os()
  # must use system
  if(os == "windows") {
    pid <- system(paste0('netstat -ano | findstr :', port))
    system(paste0('taskkill /PID', pid,' /F'))
  } else if(os == "linux") {
    # linux
    system(paste0("kill -9 $(lsof -ti tcp:", port,")"))
  } else {
    # osx
    system(paste0("lsof -ti:", port, " | xargs kill -9"))
  }
}

#' Internal function to determine if port is engaed.
#'
#' @param port to check.
is_port_engated <- function(port = 3000) {
  stopifnot(exists("port"))
  # detect OS
  os <- get_os()
  # windows
  cmd <- paste0('netstat -ano | findstr :', port)
  cmd <- switch (os,
    "osx" = paste0("lsof -ti:", port),
    "linux" = paste0("lsof -ti tcp:", port)
  )
  # must use stystem
  pid <- system(cmd, ignore.stdout = TRUE)
  if(pid == 0) return(TRUE)
  FALSE
}

#' Internal helper function to determine OS in a consistent way.
#'
get_os <- function(){
  sysinf <- Sys.info()
  if (!is.null(sysinf)){
    os <- sysinf['sysname']
    if (os == 'Darwin')
      os <- "osx"
  } else { ## mystery machine
    os <- .Platform$OS.type
    if (grepl("^darwin", R.version$os))
      os <- "osx"
    if (grepl("linux-gnu", R.version$os))
      os <- "linux"
  }
  tolower(os)
}

openURL <- function(host = "127.0.0.1", port = 8000) {
  viewer <- getOption("viewer")
  if(identical(.Platform$GUI, "RStudio") && !is.null(viewer)) {
    viewer(paste0("http://",host,":",port))
  } else {
    utils::browseURL(paste0("http://",host,":",port))
  }
}
