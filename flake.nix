{
  description = "Git cli configured by Marcus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    neovim.url = "github:marcuswhybrow/neovim";
  };

  outputs = inputs: let 
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    delta = "${pkgs.delta}/bin/delta";
    gh = "${pkgs.gh}/bin/gh";
    neovim = "${inputs.neovim.packages.x86_64-linux.nvim}/bin/nvim";
    config = pkgs.writeTextDir "git/config" ''
      [core]
        editor = ${neovim}
        pager = ${delta}

      [credential "https://github.com"]
        helper = ${gh} auth git-credential

      [delta]
        light = false
        navigate = true

      [diff]
        colorMoved = default

      [merge]
        conflictstyle = diff3

      [interactive]
        diffFilter = ${delta} --color-only

      [user]
        name = "Marcus Whybrow"
        email = "marcus@whybrow.uk"

      [init]
        defaultBranch = "main"
    '';
    wrapper = pkgs.runCommand "git" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir --parents $out/bin
      makeWrapper ${pkgs.git}/bin/git $out/bin/git \
        --set XDG_CONFIG_HOME ${config}
    '';

    fishAbbrs = pkgs.writeTextDir "share/fish/vendor_conf.d/git.fish" ''
      if status is-interactive
        abbr --add gs git status
        abbr --add ga git add .
        abbr --add gc git commit
        abbr --add gp git push
        abbr --add gd git diff
      end
    '';
  in {
    packages.x86_64-linux.git = pkgs.symlinkJoin {
      name = "git";
      paths = [
        wrapper # First packages ./bin/git takes precidence
        pkgs.git 
        fishAbbrs
      ]; 
    };

    packages.x86_64-linux.default = inputs.self.packages.x86_64-linux.git;
  };
}
