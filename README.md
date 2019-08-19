# LambdaMail
## What is it?
LambdaMail is a flexible, self-hosted, mailing list and mass-mailing system.
It's designed for small organisations who need a simple yet powerful way to send
mail.

Users can sign up to the mailing list quickly and easily. Once you have acquired
a set of recipients, send some emails using a clean web interface.
Emails are composed using a set of modular templates and plugins, written
in Ruby. LambdaMail then links to your email server to send out emails, and
can keep the sentbox clean if the account is also manned.

## Deploying
1. Ensure you have Ruby >2.4 and the corresponding Ruby devkit.
2. Ensure `lib-sqlite3dev` and `redis-server` are installed.
3. Clone LambdaMail and run `bundle`. (If this fails with errors about Bundler version, `gem install bundler`.)
4. To start LambdaMail, run `bundle exec rackup -p <port>`.
5. You also need to start Sidekiq: `bundle exec sidekiq -r ./src/main.rb`.

I ensured that both the Rack and Sidekiq commands kept running by creating
bash scripts for each, and then creating two separate PM2 services of those 
bash scripts.

## Setup
1. Place a SHA256 hex digest of a chosen admin password in `~/.local/share/lambdamail/password.txt`. (`echo PASSWORD | ruby -e "require 'digest'; puts Digest::SHA256.hexdigest gets.chomp"` can calculate this for you!)
2. Fill in all the details in `~/.local/share/lambdamail/config.json`.

Note that LambdaMail is useless unless you install some plugins. To install a 
plugin, place its folder in `~/.local/share/lambdamail/plugins`.

## Internals
At its core, LambdaMail is a database, a set of background workers for
sending mail, and a pretty web interface. LambdaMail also works using plugins.

### Database
The database is SQLite, mapped to models in Ruby using DataMapper. This database
contains the following models:

  - `Event`: An event like somebody subscribing or sending mail. These are shown
    on the admin dashboard page.
  - `PendingSubscription`: Created when somebody subscribes but has yet to click
    their confirmation email. When they've confirmed, their pending subscription
    gets deleted and they become a...
  - `Recipient`: Somebody who will recieve a mass mail. All recipients have an
    email address and some may have a name. They have a salt for securing
    unsubscriptions too. A recipient in the database is always "active": if they
    unsubscribe, they're simply deleted from the database.
  - `ComposedEmailMessage`: A big complex model representing an entire message.
    These are what is shown on the admin messages page. They contain JSON for
    the email's sections, a subject, and a reference to the template they're
    using. Once sent, it also gets a semicolon-list of the recipients it was
    sent to, and a Sidekiq batch ID (more on that later).
  - `SpecialEmailMessage`: This is a "raw" email message with simply ONE
    recipient, a subject, and a body. When a composed message is sent, a special
    message is created for each of its recipients. A special message is also
    created for subscription confirmations.

### Workers
Workers are powered by Sidekiq, a background task system for Ruby. The main Ruby
process instanties and offloads workers to another Ruby process controlled by
Sidekiq. Sidekiq also spawns threads to allow these workers to run concurrently.
(Because Sidekiq runs the codebase too, you **must** restart both Rack and
Sidekiq if you redeploy.)

Each instantiated worker is called a job. LambdaMail only has one worker, which
sends a `SpecialEmailMessage` using the configured SMTP settings, then deletes
it from the sentbox using the IMAP settings. 

This worker is used directly for one-off jobs like sending a subscription
confirmation. However, for sending a `ComposedEmailMessage`, a batch is used.
A batch is a group of jobs which fires a callback when the job finishes. So, if
you're sending to a 20-person mailing list, the following happens:

  1. The `ComposedEmailMessage` is rendered 20 times, for each recipient. 
     (We can't just render once because things like unsubscribe links will
     differ.)
  2. The render results are saved as `SpecialEmailMessage` instances in the DB.
  3. Each `SpecialEmailMessage` is sent in a batch, creating 20 jobs.
  4. Once all 20 jobs have finished, the batch looks at their results and 
     updates the status field of the `ComposedEmailMessage`.

### Web Interface
The web interface is powered by Sinatra, and is written in a "classic HTTP" 
style. GETs return an HTML page, and if it has a form, it'll typically POST
to the same URL, which will then redirect to the new resource (or back to a 
list of resources). The proper verbs (PUT, DELETE, etc) are used wherever
possible.

All pages are rendered using HAML templating, as much on the serverside as
possible. Most pages have no JS at all, though a few have a sprinkling of JS.
The "Compose Email Message" page is an exception to this rule, being a small
Vue app.

Pages under the `/admin` namespace all require authenticaion, which is simply a
single session variable. LambdaMail only has one user, the admin, so there are
no usernames and only one password.

### Plugins
Plugins are essential to LambdaMail - they provide both templates and section
kinds, and you can't compose emails without both of those things. Each plugin
is a folder within LambdaMail's `plugins` directory, containing an `info.yaml`
file and a `main.rb` file.

Here are the "core" plugin's files:

```yaml
name: Core
package: cc.aaronc.core
description: Core sections
version: 1.0.0
```

```ruby
@plugin.define_section_kind(name: 'Plain Text Section', id: 'plain-text-section') do |s|
  s.define_property(name: 'Content', type: :long_text)
  s.to_render do |props|
    props['Content']
  end
end

@plugin.define_section_kind(name: 'Markdown Section', id: 'markdown-section') do |s|
  s.define_property(name: 'Content', type: :long_text)
  s.to_render do |props|
    s.markdown(props['Content'])
  end
end
```

Plugins are only loaded when LambdaMail starts. If you create any more, or edit
them, you'll need to restart the Rack and Sidekiq processes. You'll get weird
data discrepancies if you restart one but not the other.

**LambdaMail does not gracefully handle plugins being deleted. Don't do this.**

## Testing
There's a Capybara test suite. It's not very comprehensive, but it's enough to
tell you if anything is horrifically broken. Run it with `bundle exec rspec`.

Parts of the app enter "testing mode" if RSpec is defined; data is saved into an
in-memory SQLite and emails aren't actually sent. You should be warned about
this if it happens, but please don't `require 'rspec'` in your plugins 
(although I can't think of any reason to do this).