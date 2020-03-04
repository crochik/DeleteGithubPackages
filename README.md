# Important
**BE VERY CAREFUL** Using the wrong value for any of the parameters may delete all the packages in a repository.

# Delete Github packages in a repository
It will delete all the versions of all the packages in the given repository that are older than the olderthan value.

## Create Config file
Create or modify the provided config.json file with your desired settings.

config.json:
```
{
    "token": "<github_token>",
    "owner": "Crochik",
    "project": "DeleteGithubPackages",
    "olderthan": "12/01/19"
    "package": "packagename"
}
```
* `token`: Personal github token with access to ...
* `owner`: github account
* `project`: github repository
* `olderthan`: cut off date, all versions older than this date will be deleted
* `package`: name of the package to be deleted 

## Usage
```
./DeleteGithubPackages.ps1 -Config <path>
```

* `-Config <path_to_json_config_file>` : Required parameter with path to the configuration file
* `-SkipConfirmation` : won't ask for user input (but will introduce a 5seconds delay before starting)
