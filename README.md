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

- `installers`: a directory containing custom installers.

## Packages

Packages are represented by installer scripts that install one specific part of your environment, for example there is an installer included under `installers` which install a basic nginx webserver.

The name of a package is the name of it's installer script without the `.sh` extension.

## Custom installers

You can build your own buildpack by forking this repository and adding your own installers, but if you would
like to keep your buildpack as clean as possible you can also install installer scripts in the `/build/heroku/installers`
folder of your project.

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

Note: You should NOT mark your own package as installed using `dependency_mark`, this is done for you.

## License
This project is available under the New BSD License.

[1]: https://devcenter.heroku.com/articles/buildpack-api#bin-release