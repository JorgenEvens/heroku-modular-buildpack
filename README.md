# heroku-modular-buildpack

A buildpack based on the idea of packages, delivering a modular system and basic dependency management.

## Using

It is possible to use this buildpack as is, and contain all your extra data in your project itself.
Configuration for this buildpack should always be placed inside your project under `/build/heroku/`.

A minimum configuration has at least these files living in `/build/heroku/`:

- `install`: contains a list of packages to install separated by a space or a package per line.
- `package`: the name of the buildpack as reported to heroku.
- `release`: a release file as specified by [heroku][1].

Optional components are:

- `installers`: a directory containing [custom installers][2].
- `compile`: a [custom compile](#project-specific-compile) script for your project that will be run after all the packages have been installed.
- `repos`: a file containing package repositories, the presence of this file enables the [package manager][3].

## Packages

Packages are represented by [installer scripts][2] that install one specific part of your environment, for example there is an installer included under `installers` which install a basic nginx webserver.

The name of a package is the name of it's installer script without the `.sh` extension.

## Package manager

This buildpack includes a package manager which allows you to centralize the management of your packages.

### Enabling the package manager
By default the package manager is disabled, you can enable it simply by adding a `repos` file to your `/build/heroku/` directory.

The file-format of the `repos` file is as simple as a link ( any link supported by curl ) per line of the file.

Sample `repos` file:

```
http://jorgen.evens.eu/heroku/index
http://example.com/deploy/heroku
```

### Repositories

A repository is a plain text file using the following format `<package-name> <package-link> <package-md5> <comments>` where each package is on its own line. It is important to use a space to separate the package from its link, a tab is currently not supported.

`<package-link>` is a link ( any link supported by curl ) to the [installer file][2] for the package.
`<package-md5>` is a md5 hash of the installer file which is used to check for an outdated cache.

A sample repository

```
nginx-deploy-page http://jorgen.evens.eu/heroku/nginx-deploy-page.sh 9bbb050c6bba8c7ad8f738ef056088ae # Exposes deployment information through a static page.
```

Note: Currently no versioning of packages is available. If you would like to add multiple versions you will have to include the version in the package name. `nginx-1.4.2` for example.

### Repository sample + tools

There is a [github repository][4] with some prebuilt packages in it and a script that helps you build an index of a local directory.

## Custom installers

You can build your own buildpack by forking this repository and adding your own installers, but if you would
like to keep your buildpack as clean as possible you can also install installer scripts in the `/build/heroku/installers` folder of your project.

An alternative is to use the [package manager][3] to distribute the packages.

### Variables

The buildpack passes 2 variables into the installer, these are the exact same variables as Heroku passes to the compile script.

 - $BUILD_DIR
 - $CACHE_DIR

These directories are created for you when the buildpack runs.

### Helper functions

An installer has access to some helper functions to print to the console and to manage dependencies it might require.

- `print_action`: prints the message prefixed with the '-------> ' arrow.
- `print`: prints the message prefixed with spaces to align it with `print_action`.
- `dependency_require <package>`: requires the installation of the dependency before continuing. 
- `dependency_mark <package>`: marks a package as installed. This is primarily for internal use.
- `download`: Downloads a file to the specified location and checks if the MD5 hash is correct.
- `cached_download`: Performs the same function as `download` but caches the files.

Note: You should NOT mark your own package as installed using `dependency_mark`, this is done for you.

#### `dependency_mark` use case

A sample use-case for the `dependency_mark` function is given here to illustrate its use.

If your package can be used as a drop-in replacement for another package you can mark the original package as installed so your package does not get overwritten when a different package depends on the original.

An example:

- There is a generic `nginx` package in your repository
- There is a `nginx-module` package which is nginx with a specific module compiled in.
- There is a package `nginx-status` which depends on the generic `nginx` package.

In this scenario we would like to combine `nginx-module` with `nginx-status`, if we would setup our `install` file like illustrated below we would overwrite `nginx-module` with generic `nginx` since `nginx-status` depends on it.

```
nginx-module nginx-status
```

To solve this problem we can mark `nginx` as installed at the end of our `nginx-module` installer by calling `dependency_mark nginx`.
Now when `nginx-status` is installed `nginx` will be reported as installed and `nginx-module` will not get overwritten.

### boot.sh

A `boot.sh` file is always created with a shebang `#!/bin/sh` followed by an empty line. If your installer wants to add something to the `boot.sh` file you should simple append the lines to the `${BUILD_DIR}/boot.sh` file.

It is important that you send blocking applications to the background using `&`. For example:
```
/app/vendor/nginx/sbin/nginx &
```

A `wait` will be added to the end of the boot.sh script so that the script will wait for the background tasks to complete and heroku will not think that the script exited. This way all the commands in the `boot.sh` file get executed and all services start as they are supposed to.

## Project specific compile

The project specific `compile` script has access to the same functionality as a [custom installer][2] and is for all intents and purposes a custom installer that always gets run at the end.

## Contributions

Special thanks to these people for contributing to this project

 - [Wim Mostmans](https://twitter.com/Sitebase)

## License
This project is available under the New BSD License.

[1]: https://devcenter.heroku.com/articles/buildpack-api#bin-release
[2]: #custom-installers
[3]: #package-manager
[4]: https://github.com/JorgenEvens/heroku-packages