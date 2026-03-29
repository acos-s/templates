{
  description = "My project templates";

  outputs =
    { self }:
    {
      templates = {
        "roblox.executors" = {
          path = ./roblox/executors;
          description = "Executor script template";
        };
        "roblox.studio" = {
          path = ./roblox/studio;
          description = "Roblox studio template";
        };
      };
    };
}
