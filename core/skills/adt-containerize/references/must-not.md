## Must not

* Use heavy, development-only base images for runtimes.
* Expose sensitive environment variables, tokens, or credentials inside checked-in files. Use env templates or volumes.
* Paste unretracted secrets from `.env` into references, Dockerfiles, or compose examples.
