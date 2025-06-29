# frozen_string_literal: true

# name: discourse-share-link-userid
# about: Uses user.id instead of username in share links, while supporting legacy links.
# version: 0.1
# authors: Tethys Plex
# url: https://github.com/Shinplex/discourse-share-link-userid

after_initialize do
  # ------------------------------------------------------------
  # Patch TopicsController#track_visit_to_topic
  # ------------------------------------------------------------
  module ::DiscourseShareLinkUserid
    module TopicsControllerPatch
      def track_visit_to_topic
        return if request.format.json?

        u_param         = request["u"]
        username        = nil
        tracked_user_id = nil

        if u_param.present?
          if u_param.to_s =~ /^\d+$/
            tracked_user_id = u_param.to_i          # ?u=<user.id>
          else
            username = u_param                      # ?u=<username> (兼容旧链接)
          end
        end

        TopicsController.defer_add_incoming_link(
          referer:      request.referer || flash[:referer],
          host:         request.host,
          current_user: current_user,
          topic_id:     @topic_view.topic.id,
          post_number:  @topic_view.current_post_number,
          username:     username,
          user_id:      tracked_user_id,
          ip_address:   request.remote_ip,
        )
      end
    end
  end

  ::TopicsController.prepend ::DiscourseShareLinkUserid::TopicsControllerPatch

  # ------------------------------------------------------------
  # Patch IncomingLink.add
  # ------------------------------------------------------------
  module ::DiscourseShareLinkUserid
    module IncomingLinkPatch
      def add(opts)
        # 新逻辑：优先接受 :user_id；若没有则回退到 :username
        user_id = opts[:user_id]

        if user_id.blank? && opts[:username].present?
          username = opts[:username]
          username = nil unless username.is_a?(String)
          username = nil if username&.include?("\0")

          if username
            if (u = User.select(:id).find_by(username_lower: username.downcase))
              user_id = u.id
            end
          end
        end

        opts = opts.merge(user_id: user_id)
        super(opts)
      end
    end
  end

  class ::IncomingLink
    class << self
      prepend ::DiscourseShareLinkUserid::IncomingLinkPatch
    end
  end
end
