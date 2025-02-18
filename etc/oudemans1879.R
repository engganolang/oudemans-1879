# R codes to prepare raw data for CLDF

library(tidyverse)
library(stringi)
library(readxl)

# read and save orthography profile data from EnoLEX ====
# dir.create("ortho")
# oudemans_ortho <- "https://raw.githubusercontent.com/engganolang/enolex/refs/heads/main/ortho/_07-oudemans1879_ipa_profile.tsv"
# read_tsv(oudemans_ortho,
#          col_types = c("cccccci")) |> 
#   mutate(across(where(is.character), ~replace_na(., ""))) |> 
#   write_tsv("ortho/_07-oudemans1879_ipa_profile_eno.tsv", na = "")

# read the raw word list data ====
odm1879 <- read_xlsx(path = "data-source/Oudemans_1879_wordlist.xlsx", na = "") |> 
  mutate(across(where(is.character), ~replace_na(., ""))) |> 
  mutate(Sources = "oudemans1879")

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
         Remarks = str_replace_all(Remarks, "(\\<rm\\=\"|\"\\>)", ""),
         Remarks = if_else(str_detect(Enggano, "niet aanwezig"),
                           Enggano,
                           Remarks),
         Enggano = replace(Enggano, str_detect(Enggano, "niet aanwezig"), ""))

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
                              Glottocode)) |> 
  filter(Forms != "") |> 
  distinct() |> 
  mutate(Forms = str_to_lower(Forms)) |> 
  mutate(ID = row_number())

# save languages.tsv to etc ====
odm1879_long |> 
  select(Glottocode, Glottolog_name) |> 
  distinct() |> 
  mutate(ID = paste(row_number(), "-", Glottocode, sep = ""),
         Name = Glottolog_name,
         Sources = "oudemans1879") |> 
  select(ID, Name, Glottocode, Glottolog_Name = Glottolog_name, Sources) |> 
  write_tsv("etc/languages.tsv")

# save English translation for concepticon mapping ====
# concepts_eng <- odm1879_long |> 
#   select(GLOSS = English) |> 
#   distinct() |> 
#   filter(!is.na(GLOSS)) |> 
#   mutate(NUMBER = row_number()) |> 
#   relocate(NUMBER, .before = GLOSS)
# concepts_eng |> 
#   write_tsv(paste("data-source/odm1879-gloss-ENG-to-map-", nrow(concepts_eng), ".tsv", sep = ""))

# save Dutch gloss for concepticon mapping ====
# concepts_nl <- odm1879_long |> 
#   select(GLOSS = Dutch) |> 
#   distinct() |> 
#   filter(!is.na(GLOSS)) |> 
#   mutate(NUMBER = row_number()) |> 
#   relocate(NUMBER, .before = GLOSS)
# concepts_nl |> 
#   write_tsv(paste("data-source/odm1879-gloss-NL-to-map-", nrow(concepts_nl), ".tsv", sep = ""))

# Orthography ====
## Enggano ====
eno_str <- pull(filter(odm1879_long, Doculect == "Enggano"), Forms)
eno_id <- pull(filter(odm1879_long, Doculect == "Enggano"), ID)

orth_eno <- qlcData::tokenize(strings = eno_str,
                               profile = "ortho/_07-oudemans1879_ipa_profile_eno.tsv",
                               transliterate = "Replacement",
                               method = "global",
                               ordering = NULL,
                               regex = TRUE,
                               sep.replace = "_",
                               normalize = "NFC")
orth_eno$errors
orth_eno$missing
orth_eno$strings

orth_eno_ipa <- qlcData::tokenize(strings = eno_str,
                                  profile = "ortho/_07-oudemans1879_ipa_profile_eno.tsv",
                                  transliterate = "Phoneme",
                                  method = "global",
                                  ordering = NULL,
                                  regex = TRUE,
                                  sep.replace = "_",
                                  normalize = "NFC")
orth_eno_ipa$strings <- orth_eno_ipa$strings |> 
  rename(ipa = transliterated)

orth_eno$strings <- orth_eno$strings |> 
  bind_cols(orth_eno_ipa$strings |> 
              select(ipa)) |> 
  mutate(ID = eno_id) |> 
  as_tibble()

orth_eno$strings |> 
  write_tsv("ortho/_07-oudemans1879_strings_eno.tsv")

## Nias ====
nias_str <- pull(filter(odm1879_long, Doculect == "Nias"), Forms)
nias_id <- pull(filter(odm1879_long, Doculect == "Nias"), ID)

orth_nias <- qlcData::tokenize(strings = nias_str,
                               profile = "ortho/_07-oudemans1879_ipa_profile_nias.tsv",
                               transliterate = "Replacement",
                               method = "global",
                               ordering = NULL,
                               regex = TRUE,
                               sep.replace = "_",
                               normalize = "NFC")
orth_nias$errors
orth_nias$missing

orth_nias_ipa <- qlcData::tokenize(strings = nias_str,
                                  profile = "ortho/_07-oudemans1879_ipa_profile_nias.tsv",
                                  transliterate = "Phoneme",
                                  method = "global",
                                  ordering = NULL,
                                  regex = TRUE,
                                  sep.replace = "_",
                                  normalize = "NFC")
orth_nias_ipa$strings <- orth_nias_ipa$strings |> 
  rename(ipa = transliterated)

orth_nias$strings <- orth_nias$strings |> 
  bind_cols(orth_nias_ipa$strings |> 
              select(ipa)) |> 
  mutate(ID = nias_id) |> 
  as_tibble()

orth_nias$strings |> 
  write_tsv("ortho/_07-oudemans1879_strings_nias.tsv")

## Mentawai =====
mtw_str <- pull(filter(odm1879_long, Doculect == "Mentawai"), Forms)
mtw_id <- pull(filter(odm1879_long, Doculect == "Mentawai"), ID)

orth_mtw <- qlcData::tokenize(strings = mtw_str,
                               profile = "ortho/_07-oudemans1879_ipa_profile_mtw.tsv",
                               transliterate = "Replacement",
                               method = "global",
                               ordering = NULL,
                               regex = TRUE,
                               sep.replace = "_",
                               normalize = "NFC")

orth_mtw$errors
orth_mtw$missing

orth_mtw_ipa <- qlcData::tokenize(strings = mtw_str,
                                   profile = "ortho/_07-oudemans1879_ipa_profile_mtw.tsv",
                                   transliterate = "Phoneme",
                                   method = "global",
                                   ordering = NULL,
                                   regex = TRUE,
                                   sep.replace = "_",
                                   normalize = "NFC")
orth_mtw_ipa$strings <- orth_mtw_ipa$strings |> 
  rename(ipa = transliterated)

orth_mtw$strings <- orth_mtw$strings |> 
  bind_cols(orth_mtw_ipa$strings |> 
              select(ipa)) |> 
  mutate(ID = mtw_id) |> 
  as_tibble()

orth_mtw$strings |> 
  write_tsv("ortho/_07-oudemans1879_strings_mtw.tsv")

# joining to the main table ====

odm1879_long1 <- odm1879_long |> 
  left_join(orth_nias$strings |> 
              bind_rows(orth_eno$strings) |> 
              bind_rows(orth_mtw$strings)) |> 
  select(-originals)

# dir.create("etc/orthography")

# Concepticon added to the main table ======
source("etc/oudemans1879-concepticon-processing.R")
odm1879_long2 <- odm1879_long1 |> 
  left_join(select(cnc, -ID))

# Save the main table into `raw` directory ======
odm1879_long2 |> 
  mutate(across(where(is.character), ~replace_na(., ""))) |> 
  mutate(transliterated_unsegmented = str_replace_all(transliterated, " ", "")) |> 
  relocate(transliterated_unsegmented, .after = transliterated) |> 
  write_tsv("raw/oudemans1879.tsv")
