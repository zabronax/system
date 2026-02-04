{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    home-manager.users.root.programs.git = {
      enable = true;
      settings.safe.directory = config.dotfilesPath;
    };

    home-manager.users.${config.user} = {
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = config.user;
            email = config.email;
          };

          core.pager = "${pkgs.git}/share/git/contrib/diff-highlight/diff-highlight | less -F";
          interactive.difffilter = "${pkgs.git}/share/git/contrib/diff-highlight/diff-highlight";
          pager = {
            branch = "false";
          };
          safe = {
            directory = config.dotfilesPath;
          };
          pull = {
            ff = "only";
          };
          push = {
            autoSetupRemote = "true";
          };
          init = {
            defaultBranch = "main";
          };
          rebase = {
            autosquash = "true";
          };
        }
        // lib.optionalAttrs (config.signing.keyId != null && config.signing.service == "gpg-agent") {
          # Signing configuration (uses signing service - GPG Agent)
          # Git requests signatures through GPG Agent, key material never exposed
          commit = {
            gpgsign = config.signing.signByDefault;
          };
          gpg = {
            format = "openpgp";
            # Key ID for GPG Agent to use (key material stays in agent)
            key = config.signing.keyId;
          };
        };
        ignores = [
          ".direnv/**"
          "result"
          ".DS_Store"
          ".vscode"
        ];
      };

      programs.fish.shellAbbrs = {
        g = "git";
        gs = "git status";
        gd = "git diff";
        gds = "git diff --staged";
        gdp = "git diff HEAD^";
        ga = "git add";
        gaa = "git add -A";
        gac = "git commit -am";
        gc = "git commit -m";
        gca = "git commit --amend --no-edit";
        gcae = "git commit --amend";
        gu = "git pull";
        gp = "git push";
        gl = "git log --graph --decorate --oneline -20";
        gll = "git log --graph --decorate --oneline";
        gco = "git checkout";
        gcom = ''git switch (git symbolic-ref refs/remotes/origin/HEAD | cut -d"/" -f4)'';
        gcob = "git switch -c";
        gb = "git branch";
        gpd = "git push origin -d";
        gbd = "git branch -d";
        gbD = "git branch -D";
        gdd = {
          position = "anywhere";
          setCursor = true;
          expansion = "BRANCH=% git push origin -d $BRANCH and git branch -d $BRANCH";
        };
        gr = "git reset";
        grh = "git reset --hard";
        gm = "git merge";
        gcp = "git cherry-pick";
        cdg = "cd (git rev-parse --show-toplevel)";
      };
    };
  };
}
