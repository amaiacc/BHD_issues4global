# script to download google form and format it into a md file that can be submitted as a git issue
# Amaia Carrión-Castillo, 2021.06.18

# define directories
mkdir -p project_data project_issues

# define target format, from git an example git issue --> in templates
## https://github.com/brainhackorg/global2020/issues/new?assignees=&labels=project&template=project-submission-template.md&title=


# get google form as csv output
## specify the url for the target google form
url_file="https://docs.google.com/spreadsheets/d/1AlflVlTg1KmajQrWBOUBT2XeoAUqfjB9SCQfDIPvSXo/export?gid=565678921&format=csv"
wget --no-check-certificate ${url_file} -O 'project_data/BHD2021_projects.csv' 

# run this script to create an adequatelly formatted markdown file for each project
Rscript --verbose googleForm2projectIssue.R project_data/BHD2021_projects.csv

# For each new project, open a new issue in github (BHD2021?)
cd project_issues

while IFS=" " read -r v1 v2 remainder
 do
  id=$(echo $v1 | sed 's/"//g')
  title=$(echo $v2 | sed 's/"//g')
#  echo "The title for ${id} is ${title}."
  
  echo "gh issue create --title ${title} --body-file ${id}.md"

done < list_new_projects.txt


