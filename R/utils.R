# Lista arquivos de um repositorio do Github da Curso-R
list_github_files <- function(repo, dir = NULL, ext = NULL) {

  req <- httr::GET(
    paste0(
      "https://api.github.com/repos/curso-r/",
      repo,
      "/git/trees/master?recursive=1"
    )
  )

  httr::stop_for_status(req)

  arquivos <- unlist(
    lapply(httr::content(req)$tree, "[", "path"),
    use.names = FALSE
  )

  if (!is.null(dir)) {
    arquivos <- grep(dir, arquivos, value = TRUE, fixed = TRUE)
  }

  if (!is.null(ext)) {
    arquivos <- arquivos[grep(paste0(ext, "$"), arquivos)]
  }

  return(arquivos)
}


# Lista repositórios do Github da Curso-R
list_github_repos <- function(curso) {

  res <- purrr::map(
    c(1, 2),
    ~ httr::GET(
      "https://api.github.com/orgs/curso-r/repos",
      query = list(
        type = "public",
        per_page = 100,
        direction = "desc",
        page = .x
      )
    )
  )

  purrr::map(res, httr::content) %>%
    purrr::flatten()

}

listar_turmas_recentes <- function(curso) {

  lista_repos <- list_github_repos(curso)

  tab_repos <- purrr::map_dfr(
    lista_repos,
    ~ tibble::tibble(
      Turma = .x$name,
      Github = .x$html_url,
      arquivado = .$archived,
      data = .x$created_at
    )
  )

  tab_repos %>%
    dplyr::mutate(ano = lubridate::year(lubridate::as_date(data))) %>%
    dplyr::filter(
      ano >= lubridate::year(Sys.Date()) - 1,
      stringr::str_detect(Turma, curso),
      !stringr::str_detect(Turma, "main-"),
      !arquivado
    ) %>%
    dplyr::mutate(
      Material = paste0("https://curso-r.github.io/", Turma),
      data = lubridate::make_date(
        stringr::str_sub(Turma, 1, 4),
        stringr::str_sub(Turma, 5, 6),
        "01"
      ),
      Turma = paste(
        lubridate::month(
          data,
          label = TRUE,
          abbr = FALSE,
          locale = "pt_BR.UTF-8"
        ),
        "de",
        lubridate::year(data)
      )
    ) %>%
    dplyr::arrange(desc(data)) %>%
    dplyr::slice(1:3) %>%
    dplyr::select(Turma, Material, Github)

}

#'
criar_arquivo_material <- function() {
  file.copy(
    from = system.file("material.txt", package = "CursoR"),
    to = "./"
  )
  rstudioapi::navigateToFile("material.txt")
}

