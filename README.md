# kgun-file-rename

## Installation
1. Get Ruby. This might be a bitch

## Setup
1. Create a temp directory somewhere (ex. `temp-file-rename`)
1. Open Terminal
1. Go to your temp folder (`cd ~/path/to/temp-file-rename`)
1. If you `ls` you should see nothing
1. Clone this code (`git clone https://github.com/bigpopakap/kgun-file-rename.git` or `git clone git@github.com:bigpopakap/kgun-file-rename.git`)
1. Now if you `ls` you'll see
  ```
  kgun-file-rename
  ```
1. Go back to Finder, but leave the terminal window open
1. Replace `kgun-file-rename/input` with a **COPY**, of your folders of files
1. Make a `names.csv`
   1. In Excel (or whatever), make something that looks like
      ```
      last       | first   | middle
      -----------|---------|--------
      Mehasubari | Kim     |
      Cena       | John    |
      Gruber     | Hans    |
      Jackson    | Samuel  | L
      ```
   1. Export as a CSV, call it `names.csv`
   1. Make sure the CSV doesn't have column titles in it
   1. Put it in your temp folder
1. It should now look like:
   ```
   temp-file-rename
   -> kgun-file-rename
     -> input
        -> CV
          -> asdfasd-some-file.pdf
          -> a92hfhs-other-file.pdf
        -> Statement
          -> 2sdfsdf-blah.doc.pdf
        ...
   -> names.csv
   ```

## Dry run
1. Open Terminal, go back to your temp directory
1. `chmod u+x kgun-file-rename/main.rb`
1. `ruby kgun-file-rename/main.rb`

## Run for real
1. Open Terminal, go back to your temp directory
1. `chmod u+x kgun-file-rename/main.rb`
1. TODO make a way to actually execute this
