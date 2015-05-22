require_relative '../test_helper'

describe HipchatNotificationRenderer do
  describe "starting" do
    it "renders a nicely formatted notification" do
      changeset = stub("changeset")
      deploy = stub("deploy", short_reference: "xyz", changeset: changeset)

      author1 = "author1"
      author2 = "author2"
      changeset.stubs(:author_names).returns([author1, author2])

      commit1 = stub("commit1", url: "#", author_name: "author1", summary: "Introduce bug")
      commit2 = stub("commit2", url: "#", author_name: "author2", summary: "Fix bug")
      changeset.stubs(:commits).returns([commit1, commit2])

      file1 = stub("file1", status: "added", filename: "foo.rb")
      file2 = stub("file2", status: "modified", filename: "bar.rb")
      changeset.stubs(:files).returns([file1, file2])

      subject = "Deploy starting"

      result = HipchatNotificationRenderer.render(deploy, subject)

      result.must_equal <<-RESULT.strip_heredoc.chomp
  Deploy starting
  2 commits by author1 and author2.
  <br>
  <strong>Files changed:</strong>
  <ul>
    <li>A foo.rb</li>
    <li>M bar.rb</li>
  </ul>
  <strong>Commits:</strong>
  <ol>
    <li><a href='#'>(author1)</a>: Introduce bug</li>
    <li><a href='#'>(author2)</a>: Fix bug</li>
  <ol>
      RESULT
    end
  end
end
