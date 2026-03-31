# philiprehberger-timeout_kit

[![Tests](https://github.com/philiprehberger/rb-timeout-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-timeout-kit/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-timeout_kit.svg)](https://rubygems.org/gems/philiprehberger-timeout_kit)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-timeout-kit)](https://github.com/philiprehberger/rb-timeout-kit/commits/main)

Safe timeout patterns without Thread.raise

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-timeout_kit"
```

Or install directly:

```bash
gem install philiprehberger-timeout_kit
```

## Usage

```ruby
require "philiprehberger/timeout_kit"

Philiprehberger::TimeoutKit.deadline(5) do |d|
  loop do
    d.check!  # raises DeadlineExceeded if time is up
    process_next_item
  end
end
```

### Remaining Time

```ruby
Philiprehberger::TimeoutKit.deadline(10) do |d|
  while d.remaining > 1
    do_work
    d.check!
  end
  puts "Only #{d.remaining}s left, wrapping up"
end
```

### Nested Deadlines

```ruby
Philiprehberger::TimeoutKit.deadline(30) do |outer|
  # Inner deadline is tighter, so it takes precedence
  Philiprehberger::TimeoutKit.deadline(5) do |inner|
    inner.check!
    puts inner.remaining  # <= 5
  end

  # After inner block, outer deadline is restored
  outer.check!
  puts outer.remaining  # <= 30
end
```

### Deadline Naming

```ruby
Philiprehberger::TimeoutKit.deadline(10, name: 'db_query') do |d|
  d.check!  # raises "Deadline 'db_query' exceeded" if expired
  puts d.name  # => "db_query"
end
```

### Deadline Callbacks

```ruby
Philiprehberger::TimeoutKit.deadline(10, on_expire: -> { cleanup() }) do |d|
  loop do
    d.check!  # fires callback once on first expiry detection
    process_next_item
  end
end

# Or register via block
Philiprehberger::TimeoutKit.deadline(10) do |d|
  d.on_expire { cleanup() }
  loop do
    d.check!
    process_next_item
  end
end
```

### Grace Period

```ruby
Philiprehberger::TimeoutKit.deadline(10, grace: 2) do |d|
  loop do
    d.check!  # does not raise during 2s grace period
    break if d.expired?

    process_next_item
  end

  if d.in_grace?
    puts "Grace period: #{d.grace_remaining}s left to wrap up"
  end
end
```

### Cooperative Timeout

```ruby
Philiprehberger::TimeoutKit.cooperative(5) do |t|
  items.each do |item|
    t.check!
    process(item)
  end
end
```

### Current Deadline

```ruby
Philiprehberger::TimeoutKit.deadline(10) do |_d|
  current = Philiprehberger::TimeoutKit.current_deadline
  puts current.remaining
end
```

## API

| Method | Description |
|--------|-------------|
| `.deadline(seconds, name:, grace:, on_expire:) { \|d\| }` | Execute a block with a cooperative deadline |
| `.cooperative(seconds) { \|t\| }` | Execute a block with a simple cooperative timeout |
| `.current_deadline` | Return the current active deadline or nil |
| `Deadline#check!` | Raise `DeadlineExceeded` if the deadline has passed (respects grace period) |
| `Deadline#remaining` | Seconds remaining until the primary deadline (negative during grace) |
| `Deadline#expired?` | Whether the primary deadline has passed |
| `Deadline#name` | The human-readable name for this deadline (nil if not set) |
| `Deadline#in_grace?` | Whether the deadline is in the grace period |
| `Deadline#grace_remaining` | Seconds remaining in the grace period (0.0 if none) |
| `Deadline#on_expire { }` | Register a callback that fires once on expiry detection |
| `DeadlineExceeded` | Raised when a deadline or timeout expires |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-timeout-kit)

🐛 [Report issues](https://github.com/philiprehberger/rb-timeout-kit/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-timeout-kit/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
