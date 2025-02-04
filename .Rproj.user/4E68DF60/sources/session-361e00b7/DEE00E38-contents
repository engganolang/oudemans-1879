# R codes to prepare raw data for CLDF

library(tidyverse)
library(stringi)
library(readxl)

# read and save orthography profile data from EnoLEX ====
# dir.create("ortho")
oudemans_ortho <- "https://raw.githubusercontent.com/engganolang/enolex/refs/heads/main/ortho/_07-oudemans1879_ipa_profile.tsv"
read_tsv(oudemans_ortho,
         col_types = c("cccccci")) |> 
  mutate(across(where(is.character), ~replace_na(., ""))) |> 
  write_tsv("ortho/_07-oudemans1879_ipa_profile.tsv", na = "")

# read the raw word list data ====
odm1879 <- read_xlsx(path = "data-source/Oudemans_1879_wordlist.xlsx", na = "") |> 
  mutate(across(where(is.character), ~replace_na(., "")))

# check if there are multiple forms in a cell ====
odm1879 |> filter(if_any(where(is.character), ~str_detect(., ";")))
# # A tibble: 3 × 7
# English Dutch  Enggano Mentawai      Nias                                                PAGE Commons
# <chr>   <chr>  <chr>   <chr>         <chr>                                              <dbl> <chr>  
#   1 shield  schild ékieahe koerâbi       "dangé<rm=\"groot\"> ; toelo toeloe<rm=\"klein\">"   486 ""     
# 2 I       ik     oewa    akoe ; mangaû "jaôdô"                                              487 ""     
# 3 you     gij    oh      ekéo          "eû ; jaôgô"                                         487 ""

# check if there are tags in the data
odm1879 |> filter(if_any(where(is.character), ~str_detect(., "\\<")))
# # A tibble: 1 × 7
# English Dutch  Enggano Mentawai Nias                                                PAGE Commons
# <chr>   <chr>  <chr>   <chr>    <chr>                                              <dbl> <chr>  
#   1 shield  schild ékieahe koerâbi  "dangé<rm=\"groot\"> ; toelo toeloe<rm=\"klein\">"   486 "" 

# split multiple forms into a single form per cell & extract remarks ====
odm1879 <- odm1879 |> 
  mutate(Mentawai = str_split(Mentawai, " ; ")) |> 
  unnest_longer(Mentawai) |> 
  mutate(Nias = str_split(Nias, " ; ")) |> 
  unnest_longer(Nias) |> 
  mutate(Remarks = str_extract(Nias, "\\<rm.+?\\>"),
         Nias = str_replace_all(Nias, "\\<rm.+?\\>", ""),
         Remarks = replace_na(Remarks, ""),
         Remarks = str_replace_all(Remarks, "(\\<rm\\=\"|\"\\>)", ""))

odm1879 |> filter(if_any(where(is.character), ~str_detect(., "(;|\\<)")))
# A tibble: 0 × 8
# ℹ 8 variables: English <chr>, Dutch <chr>, Enggano <chr>, Mentawai <chr>, Nias <chr>, PAGE <dbl>,
#   Commons <chr>, Remarks <chr>

# Turn to longer table and add Glottocode and Glottolog Name ====
odm1879_long <- odm1879 |> 
  pivot_longer(cols = c(Enggano, Mentawai, Nias), names_to = "Doculect", values_to = "Forms") |> 
  mutate(Glottocode = "ment1249",
         Glottolog_name = Doculect,
         Glottocode = if_else(Doculect == "Enggano",
                              "engg1245",
                              Glottocode),
         Glottocode = if_else(Doculect == "Nias",
                              "nias1242",
                              Glottocode))

# save languages.tsv to etc ====
odm1879_long |> 
  select(Glottocode, Glottolog_name) |> 
  distinct() |> 
  mutate(ID = paste(row_number(), "-", Glottocode, sep = ""),
         Name = Glottolog_name) |> 
  select(ID, Name, Glottocode, Glottolog_name) |> 
  write_tsv("etc/languages.tsv")

# save English translation for concepticon mapping ====
concepts_eng <- odm1879_long |> 
  select(GLOSS = English) |> 
  distinct() |> 
  filter(!is.na(GLOSS)) |> 
  mutate(NUMBER = row_number()) |> 
  relocate(NUMBER, .before = GLOSS)
concepts_eng |> 
  write_tsv(paste("data-source/odm1879-gloss-ENG-to-map-", nrow(concepts_eng), ".tsv", sep = ""))

# save Dutch gloss for concepticon mapping ====
concepts_nl <- odm1879_long |> 
  select(GLOSS = Dutch) |> 
  distinct() |> 
  filter(!is.na(GLOSS)) |> 
  mutate(NUMBER = row_number()) |> 
  relocate(NUMBER, .before = GLOSS)
concepts_nl |> 
  write_tsv(paste("data-source/odm1879-gloss-NL-to-map-", nrow(concepts_nl), ".tsv", sep = ""))
