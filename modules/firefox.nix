{ lib, pkgs, tridactyl, ublock-origin, ... }:

{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.tridactyl-native ];

    policies = {
      PasswordManagerEnabled = false;
      OfferToSaveLogins = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      DontCheckDefaultBrowser = true;
      DisableProfileImport = true;
      NoDefaultBookmarks = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        MoreFromMozilla = false;
        SkipOnboarding = true;
        UrlbarInterventions = false;
        FirefoxLabs = false;
        Locked = true;
      };

      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFeedbackCommands = true;
      DisableSetDesktopBackground = true;
      FirefoxHome = {
        SponsoredTopSites = false;
        SponsoredPocket = false;
        Pocket = false;
        Highlights = false;
        Snippets = false;
        Locked = true;
      };
      FirefoxSuggest = {
        SponsoredSuggestions = false;
        ImproveSuggest = false;
        Locked = true;
      };
      GenerativeAI.Enabled = false;

      Preferences = {
        "browser.aboutConfig.showWarning" = false;
        "browser.tabs.warnOnClose" = false;
      };
    };

    policies.ExtensionSettings = lib.mapAttrs (_id: xpi: {
      installation_mode = "normal_installed";
      install_url = "file://${xpi}";
      private_browsing = true;
      updates_disabled = true;
    }) {
      "tridactyl.vim@cmcaine.co.uk" = pkgs.runCommand "tridactyl.xpi" { } "cp ${tridactyl} $out";
      "uBlock0@raymondhill.net" = pkgs.runCommand "ublock-origin.xpi" { } "cp ${ublock-origin} $out";
    };
  };

  xdg.configFile."tridactyl/tridactylrc".source = ../config/tridactylrc;
}
