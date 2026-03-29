{
  description = "My project templates";

  outputs =
    { self }:
    {
      templates = {
        roblox = {
          "executors" = {
            path = ./roblox/executors;
            description = "Executor script template";
          };
          vue = {
            path = ./roblox/studio;
            description = "Roblox studio template";
          };
        };
      };

      checks = builtins.mapAttrs (
        category: templates:
        builtins.mapAttrs (name: tmpl: {
          templateExists = builtins.pathExists (tmpl.path);
        }) templates
      ) self.templates;
    };
}
