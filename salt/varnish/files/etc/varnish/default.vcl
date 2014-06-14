probe healthcheck {
    .request =
        "GET / HTTP/1.1"
        "Host: static.mall.com"
        "Connection: close";
    .interval = 60s;
    .timeout = 0.3 s;
    .window = 8;
    .threshold = 3;
    .initial = 3;
    .expected_response = 200;
}

backend static_01 {
    .host = "{{ pillar['varnish_static_01'] }}";
    .port = "80";
    .probe = healthcheck;
}

backend static_02 {
    .host = "{{ pillar['varnish_static_02'] }}";
    .port = "80";
    .probe = healthcheck;
}

backend static_03 {
    .host = "{{ pillar['varnish_static_03'] }}";
    .port = "80";
    .probe = healthcheck;
}

director static random {
    .retries = 5;
    {
        .backend = static_01;
        .weight  = 5;
    }
    {
        .backend  = static_02;
        .weight   = 5;
    }
    {
        .backend  = static_03;
        .weight   = 5;
    }
}

acl purge {
  "localhost";
  "172.16.100.0"/24;
}

sub vcl_recv {
    if (req.restarts == 0) {
        if (req.http.x-forwarded-for) {
            set req.http.X-Forwarded-For =
                req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    if (req.request == "PURGE") {
        if (!client.ip ~ purge) {
            error 405 "Not allowed.";
        }
        return(lookup);
    }

    if (req.http.host ~ "(?i)^static[0-9]?.mall.com$") {
        set req.backend = static;
    }

    if (req.request != "GET" && req.request != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pass);
    }

    # normalize Accept-Encoding to reduce vary
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|jpeg|png|gif|ico|gz|tgz|bz2|tbz|mp3|ogg)$") {
            unset req.http.Accept-Encoding;
        } elsif (req.http.User-Agent ~ "MSIE 6") {
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
     }

    if (req.url ~ "(?i)\.(js|css|ico|gif|jpg|jpeg|png|xml|htm|html|swf|flv)$") {
        unset req.http.Cookie;
    }

    if (req.http.referer ~ "http://.*" && req.url ~ "\.(js|css|ico|gif|jpg|jpeg|png|xml|htm|html|swf|flv)$") {
        call daolian;
    }    

    return (lookup);
}

sub daolian {
       if ( !(req.http.referer ~ "http://.*\.mall\.com"
              || req.http.referer ~ "http://mall\.com"
              )) {
                  error 404 "Not Found!";
              }
}

sub vcl_pipe {
    set req.http.connection = "close";
}

sub vcl_pass {
    return (pass);
}

sub vcl_hit {
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged.";
    }
    return (deliver);
}

sub vcl_miss {
    if (req.request == "PURGE") {
        purge;
        error 404 "Not in cache.";
    }
    return (fetch);
}

sub vcl_fetch {
    if (beresp.ttl <= 0s ||
        # beresp.http.Set-Cookie ||
        beresp.http.Vary == "*") {
                set beresp.ttl = 3600 s;
                return (hit_for_pass);
    }
    if (beresp.status == 500 || beresp.status == 501 || beresp.status == 502 ||
        beresp.status == 503 || beresp.status == 504) {
        return (restart);
    }
    return (deliver);
}

sub vcl_deliver {
    set resp.http.x-hits = obj.hits;
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HITS from {{ salt['grains.get']('fqdn', 'mall') }}";
    } else {
        set resp.http.X-Cache = "MISS from {{ salt['grains.get']('fqdn', 'mall') }}";
    }
    return (deliver);
}

sub vcl_error {
    return (deliver);
}

sub vcl_init {
        return (ok);
}

sub vcl_fini {
        return (ok);
}
