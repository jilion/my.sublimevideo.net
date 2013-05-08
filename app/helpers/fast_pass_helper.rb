#
# Helper module for integrating Get Satisfaction's FastPass single-sign-on service into a Ruby web
# app. Use #url to create a signed FastPass URL, and #script to generate the JS-based integration.
#
module FastPassHelper

  # extend ERB::Util
  #
  # Generates a FastPass SCRIPT tag. The script will automatically rewrite all GetSatisfaction
  # URLs to include a 'fastpass' query parameter with a signed fastpass URL.
  #
  def fastpass_script(args = {})
    <<-EOS
    <script type="text/javascript">
      var GSFN;
      if(GSFN == undefined) { GSFN = {}; }

      (function(){
        add_js = function(jsid, url) {
          var head = document.getElementsByTagName("head")[0];
          script = document.createElement('script');
          script.id = jsid;
          script.type = 'text/javascript';
          script.src = url;
          head.appendChild(script);
        }
        add_js("fastpass_common", document.location.protocol + "//#{fastpass_domain}/javascripts/fastpass.js");

        if(window.onload) { var old_load = window.onload; }
        window.onload = function() {
          if(old_load) old_load();
          add_js("fastpass", #{fastpass_url(args).to_json});
        }
      })()

    </script>
    EOS
  end

  private

  def fastpass_domain
    'getsatisfaction.com'
  end

  #
  # Generates a FastPass URL with the given +email+, +name+, and +uid+ signed with the provided
  # consumer +key+ and +secret+ in the +args+ argument. The +key+ and +secret+ should match those provided in the company
  # admin interface.
  #
  def fastpass_url(args = {})
    consumer = OAuth::Consumer.new(args.fetch(:key), args.fetch(:secret))
    uri = URI.parse(args.fetch(:secure) ? "https://#{fastpass_domain}/fastpass" : "http://#{fastpass_domain}/fastpass")
    params = args.slice(:email, :name, :uid)

    uri.query = params.to_query

    http         = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    request      = Net::HTTP::Get.new(uri.request_uri)
    request.oauth!(http, consumer, nil, scheme: 'query_string')

    # re-apply params with signature to the uri
    query = params.merge(request.oauth_helper.oauth_parameters).merge('oauth_signature' => request.oauth_helper.signature)
    uri.query = query.to_query

    uri.to_s
  end
end
