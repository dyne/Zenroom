# Zenroom commits

Zenroom project follows the [Conventional Commits Standard](https://www.conventionalcommits.org/en/v1.0.0/) to provide a clear and explicit commit history and to automate the [Semantic Versioning](https://semver.org/). A brief overview of both specifications is provided below.

## Semantic version

Given a version number `MAJOR.MINOR.PATCH`, increment the:
- `MAJOR` version when you make incopatible API changes.
- `MINOR` version when you add functionality in a backwards compatible manner.
- `PATCH` version when you make backwards compatible bug fixes.

## Conventional commits

Commits must comply with the following form:

```
<type>(<optional scope>): <description>
empty separator line
<optional body>
empty separator line
<optional footer>
```

The relevant commit keywords are:
- **fix**: a commit of type `fix` patches a bug in the code (`PATCH`)
- **feat**: a commit of type `feat` introduces a new feature in the code (`MINOR`)
- **BREAKING CHANGE**: a commit that has a footer `BREAKING CHANGE:` introduces a breaking chenge (`MAJOR`). Note: a breaking change can be part of any commits' type.

Other commits' **type** are allowed, for example those based on the [Angular convention](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines):
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to the CI configuration files and scripts
- **docs**: Changes to the documentation
- **perf**: Changes that improves performance
- **refactor**: Changes that neither fixes a bug nor adds a feature
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **test**: Changes to the tests

These types have no implicit effect in semantic versioning unless they include a **BREAKING CHANGE** footer.

### Specification
The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in the following section are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

1. Commits **MUST** be prefixed with a type, which consists of a noun, `feat`, `fix`, etc., followed by the **OPTIONAL** scope, and **REQUIRED** terminal colon and space.
2. The type `feat` **MUST** be used when a commit adds a new feature to your application or library.
3. The type `fix` **MUST** be used when a commit represents a bug fix for your application.
4. A scope **MAY** be provided after a type. A scope **MUST** consist of a noun describing a section of the codebase surrounded by parenthesis, e.g., `fix(parser):`
5. A description **MUST** immediately follow the colon and space after the type/scope prefix. The description is a short summary of the code changes, e.g., `fix: array parsing issue when multiple spaces were contained in string`.
6. A longer commit body **MAY** be provided after the short description, providing additional contextual information about the code changes. The body **MUST** begin one blank line after the description.
7. A commit body is free-form and **MAY** consist of any number of newline separated paragraphs.
8. One or more footers **MAY** be provided one blank line after the body. Each footer **MUST** consist of a word token, followed by either a `:<space>` or `<space>#` separator, followed by a string value (this is inspired by the [git trailer convention](https://git-scm.com/docs/git-interpret-trailers)).
9. A footer’s token **MUST** use `-` in place of whitespace characters, e.g., `Acked-by` (this helps differentiate the footer section from a multi-paragraph body). An exception is made for `BREAKING CHANGE`, which **MAY** also be used as a token.
10. A footer’s value **MAY** contain spaces and newlines, and parsing **MUST** terminate when the next valid footer token/separator pair is observed.
11. Breaking changes **MUST** be indicated in the type/scope prefix of a commit, or as an entry in the footer.
12. If included as a footer, a breaking change **MUST** consist of the uppercase text `BREAKING CHANGE`, followed by a colon, space, and description, e.g., `BREAKING CHANGE: environment variables now take precedence over config files`.
13. Types other than `feat` and `fix` **MAY** be used in your commit messages, e.g., `docs: updated ref docs`.
14. The units of information that make up Conventional Commits **MUST NOT** be treated as case sensitive by implementors, with the exception of `BREAKING CHANGE` which **MUST** be uppercase.
15. `BREAKING-CHANGE` **MUST** be synonymous with `BREAKING CHANGE`, when used as a token in a footer.

**Important**:  
Covnetional commit allows also to indicate a `BREAKING CHANGE` appending a `!` after type/scope, but this is not supported from our tool, thus the `BREAKING CHANGE` **MUST** be used to create a `MAJOR` release.

## Examples

In this section some commit examples are provided. Moreover, suppose to start from version `1.0.0`, we will also see how the version will be incremented.

### fix

Commits that fix some bugs.

```
fix: buffer overflow
```

```
fix(bitcoin): address import and export with float
```

The version after one of these commits will be increased to `1.0.1`

### feat

Commits that add a new feature.

```
feat: zencode split statement
```

```
feat(eddsa): create the eddsa key from secret
```

The version after one of these commits will be `1.1.0`

### BREAKING CHANGE

Commits that introduce incopatible API changes.

```
feat: introduce keyring for key management

BREAKING CHANGE: use of 'keypair' is deprecated in favor of 'keyring'
```
The version after one of these commits will be `2.0.0`

### Additional types

Types other than `fix` and `feat` have no implicit effect in **Semantic Versioning** unless they include a `BREAKING CHANGE`.

```
ci: build python wheels for armv7
```

```
docs: update ecdh documentation
```

The version after these commits will be `1.0.0`.
