# Bash script to run pyconcepticon for the first Concepticon mapping of the English translation of the Dutch gloss

## activate the virtual environment
source "/c/Users/GRajeg/OneDrive - Nexus365/Documents/cldf/.venv/Scripts/activate"

## run pyconcepticon
concepticon --repos "/c/Users/GRajeg/OneDrive - Nexus365/Documents/cldf/concepticon-data" \
map_concepts "data-source/odm1879-gloss-ENG-to-map-155.tsv" --language en --output "data-source/odm1879-gloss-ENG-to-EDIT-155.tsv"
