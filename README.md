## Statistical Machine Learning for *Listeria monocytogene* Food Source Attribution

This repository holds files related to the final project in PHP2550 Practical Data Analysis: *Statistical Machine Learning for Foodborne Disease Source Attribution* using *L. monocytogene* pathogen data downloaded from the [NCBI Pathogen Detection Database](https://www.ncbi.nlm.nih.gov/pathogens/) conducted in Fall 2022, School of Public Health, Brown University. This project sought to use ensemble-based machine learning methods and core genome multilocus sequence typing (cgMLST) data and other selected information about the sampled *Listeria monocytogenes* isolates in the United States (US). We seek to examine these data more closely and employ statistical methods to extract patterns, as well as, develop a throughout statistical machine learning classification model for *Listeria monocytogenes* pathogen
food source attribution. Ultimately, we hope our model and result can help reduce foodborne disease incidence by proposing ways of enhancing food safety, and improve public health. 

------------------------------------------------------------

## Repository Organization 

- `data`: This folder contains the `listeria_isolates.csv` data file used to conduct the analyses in our study. This is the cleaned data from the raw data files downloaded directly from the [NCBI website](https://www.ncbi.nlm.nih.gov/pathogens/). This folder also contains the `analysis_script.R`, which is the code used in the initial Exploratory Data Analysis (EDA), updated data pre-processing and brief use cases for sanity check. We also include the updated dataset used to conduct several brief use cases and made comparisons between different models. The training and the test set we divided are also contained.

- `figures`: This folder contains flow chart of the data cleaning process used in this project. 

- `main_files/figure-latex`: This file contains all figures we get from the full Exploratory Data Analysis report done for the project.

- `methodology_files/figure-latex`: This folder contains curves based on the implemented naive Bayesian model.

- `main.Rmd`, `main.md` and `main.pdf`: This files contain the written Literature Review and full Exploratory Data Analysis report done for this project. The code is hidden in the pdf version. 

- `methodology.Rmd`, `methodology.md` and `methodology.pdf`: This files contain the written Methods and Analysis Plan report done for this project. The code is hidden in the pdf version. 

- `references.bib`: This file contains all the reference literature and updated Methods and Analysis Plan we have used in this project.

More folders and files to be added throughout the course of the project.

-------------------------------------------------------------
## Collaborators

[Amos Okutse](https://github.com/okutse)

[Rophence Ojiambo](https://github.com/rophenceojiambo)

[Zexuan Yu](https://github.com/xueshenfec)

-------------------------------------------------------------
