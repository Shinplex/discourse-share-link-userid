/**
 * Override the core helper so that share links include ?u=<user.id>
 * instead of ?u=<username>.  Works on the client only; server patches
 * handle incoming links for compatibility.
 */
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "share-link-userid",

  initialize() {
    withPluginApi("0.8.7", () => {
      const helperModule = require("discourse/helpers/share-url");
      if (helperModule?.resolveShareUrl) {
        helperModule.resolveShareUrl = function (url, user) {
          const siteSettings = require("discourse/lib/site-settings").default;
          const badgesEnabled = siteSettings.enable_badges;
          const allowUsername = siteSettings.allow_username_in_share_links;
          const userSuffix =
            user && badgesEnabled && allowUsername ? `?u=${user.id}` : "";
          return url + userSuffix;
        };
      }
    });
  },
};
