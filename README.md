# logstash-codec-loginsight

This is a plugin for [Logstash](https://github.com/elastic/logstash), converting events received from [VMware vRealize Log Insight](https://www.vmware.com/support/pubs/log-insight-pubs.html) via [logstash-input-http](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-http.html).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Installation from rubygems

[logstash-codec-loginsight](http://rubygems.org/gems/logstash-codec-loginsight) is hosted on rubygems.org. [Download and install the latest gem](https://www.elastic.co/guide/en/logstash/current/working-with-plugins.html) in your Logstash deployment:

```sh
bin/logstash-plugin install logstash-codec-loginsight
```

Verify installed version:
```sh
bin/logstash-plugin list --verbose logstash-codec-loginsight
logstash-codec-loginsight (x.y.z)
```

## Usage

The codec is designed to be chained with the `logstash-input-http` plugin. Log events are forwarded from Log Insight with CFAPI on port 9000 (non-ssl) or 9543 (ssl), targetting and instance of `logstash-input-http` configured with additional codec.

```
input {
  http {
    port=>9000
    additional_codecs=>{ "application/json" => "loginsight"}
  }
}
```

| option | default | notes |
| --- | --- | --- |
| `charset`  | `UTF-8` | The character encoding used in this codec.

## AsciiDocs

Logstash provides infrastructure to automatically generate documentation for this plugin. We use the asciidoc format to write documentation so any comments in the source code will be first converted into asciidoc and then into html. All plugin documentation are placed under one [central location](http://www.elastic.co/guide/en/logstash/current/).

- For formatting code or config example, you can use the asciidoc `[source,ruby]` directive
- For more asciidoc formatting tips, see the excellent reference here https://github.com/elastic/docs#asciidoc-guide

## Need Help?

Need help? Try #logstash on freenode IRC or the https://discuss.elastic.co/c/logstash discussion forum.

## Developing

### 1. Plugin Developement and Testing

#### Code
- To get started, you'll need JRuby with the Bundler gem installed.

- Create a new plugin or clone and existing from the GitHub [logstash-plugins](https://github.com/logstash-plugins) organization. We also provide [example plugins](https://github.com/logstash-plugins?query=example).

- Install dependencies
```sh
bundle install
```

#### Test

- Update your dependencies

```sh
bundle install
```

- Run tests

```sh
bundle exec rspec
```

### 2. Running the local, unpublished plugin in Logstash

#### 2.1 Run in a local Logstash clone

- Edit Logstash `Gemfile` and add the local plugin path, for example:
```ruby
gem "logstash-codec-loginsight", :path => "/your/local/logstash-codec-loginsight"
```
- Install plugin
```sh
# Logstash 2.3 and higher
bin/logstash-plugin install --no-verify

# Prior to Logstash 2.3
bin/plugin install --no-verify

```
- Run Logstash with your plugin
```sh
bin/logstash --debug --log.level=debug -e 'input { http {port=>9000 additional_codecs=>{ "application/json" => "loginsight"} } } output { stdout {codec=>rubydebug} }'
```
At this point any modifications to the plugin code will be applied to this local Logstash setup. After modifying the plugin, simply rerun Logstash.

#### 2.2 Run in an installed Logstash

You can use the same **2.1** method to run your plugin in an installed Logstash by editing its `Gemfile` and pointing the `:path` to your local plugin development directory or you can build the gem and install it using:

- Build your plugin gem
```sh
gem build logstash-filter-awesome.gemspec
```
- Install the plugin from the Logstash home
```sh
# Logstash 2.3 and higher
bin/logstash-plugin install --no-verify

# Prior to Logstash 2.3
bin/plugin install --no-verify

```
- Start Logstash and proceed to test the plugin

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

For more information about contributing, see the [CONTRIBUTING](https://github.com/elastic/logstash/blob/master/CONTRIBUTING.md) file.
