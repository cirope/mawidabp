require 'octokit'
require 'git'
require 'yaml'
require 'fileutils'
require 'openai'

# Configuration
REPO = 'cirope/mawidabp'
PROJECT_ID = 5
CHANGELOG_EN = 'CHANGELOG.en.md'
CHANGELOG_ES = 'CHANGELOG.es.md'
GITHUB_TOKEN = ENV['GITHUB_TOKEN']
OPENAI_API_KEY = ENV['OPENAI_API_KEY']

# Initialize GitHub client
client = Octokit::Client.new(access_token: GITHUB_TOKEN)

# Initialize Git repository
git = Git.open('.')

# Initialize OpenAI client
openai_client = OpenAI::Client.new(api_key: OPENAI_API_KEY)

# Extract commit history
def extract_commit_history(git)
  commits = []
  git.log.each do |commit|
    commits << {
      sha: commit.sha,
      message: commit.message,
      date: commit.date
    }
  end
  commits
end

# Extract project activities
def extract_project_activities(client, repo, project_id)
  activities = []
  columns = client.project_columns(project_id)
  columns.each do |column|
    cards = client.column_cards(column.id)
    cards.each do |card|
      activities << {
        column: column.name,
        note: card.note,
        updated_at: card.updated_at
      }
    end
  end
  activities
end

# Generate summary using OpenAI
def generate_summary(openai_client, text)
  response = openai_client.completions(
    engine: 'davinci',
    prompt: "Summarize the following text:\n\n#{text}",
    max_tokens: 50
  )
  response.choices.first.text.strip
end

# Translate text using OpenAI
def translate_text(openai_client, text, target_language)
  response = openai_client.completions(
    engine: 'davinci',
    prompt: "Translate the following text to #{target_language}:\n\n#{text}",
    max_tokens: 50
  )
  response.choices.first.text.strip
end

# Translate changelog entries to Spanish
def translate_to_spanish(openai_client, entries)
  translations = {
    "Added" => "Añadido",
    "Changed" => "Cambiado",
    "Deprecated" => "Obsoleto",
    "Removed" => "Eliminado",
    "Fixed" => "Arreglado",
    "Security" => "Seguridad"
  }
  entries.map do |entry|
    {
      section: translations[entry[:section]],
      message: translate_text(openai_client, entry[:message], 'Spanish'),
      date: entry[:date]
    }
  end
end

# Generate changelog content
def generate_changelog_content(openai_client, commits, activities)
  changelog = {
    "Unreleased" => {
      "Added" => [],
      "Changed" => [],
      "Deprecated" => [],
      "Removed" => [],
      "Fixed" => [],
      "Security" => []
    }
  }

  commits.each do |commit|
    summary = generate_summary(openai_client, commit[:message])
    changelog["Unreleased"]["Added"] << {
      section: "Added",
      message: summary,
      date: commit[:date]
    }
  end

  activities.each do |activity|
    summary = generate_summary(openai_client, activity[:note])
    changelog["Unreleased"]["Added"] << {
      section: "Added",
      message: summary,
      date: activity[:updated_at]
    }
  end

  changelog
end

# Write changelog to file
def write_changelog(file, changelog)
  File.open(file, 'w') do |f|
    f.puts "# Changelog"
    f.puts
    changelog.each do |version, sections|
      f.puts "## [#{version}]"
      f.puts
      sections.each do |section, entries|
        f.puts "### #{section}"
        f.puts
        entries.each do |entry|
          f.puts "- #{entry[:message]} (#{entry[:date]})"
        end
        f.puts
      end
    end
  end
end

# Main script
commits = extract_commit_history(git)
activities = extract_project_activities(client, REPO, PROJECT_ID)
changelog = generate_changelog_content(openai_client, commits, activities)
changelog_es = translate_to_spanish(openai_client, changelog["Unreleased"]["Added"])

write_changelog(CHANGELOG_EN, changelog)
write_changelog(CHANGELOG_ES, changelog_es)
