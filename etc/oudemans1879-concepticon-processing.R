library(tidyverse)

cnc <- read_tsv("data-source/odm1879-gloss-ENG-to-EDIT-155.tsv") |> 
  rename(ID = NUMBER,
         English = GLOSS,
         Concepticon_ID = CONCEPTICON_ID,
         Concepticon_Gloss = CONCEPTICON_GLOSS) |> 
  select(-SIMILARITY)
cnc |> 
  write_tsv("etc/concepts.tsv")
