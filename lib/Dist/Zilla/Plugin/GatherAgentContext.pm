package Dist::Zilla::Plugin::GatherAgentContext;
# ABSTRACT: Snapshot the agent context (.claude/.codex/CLAUDE.md/AGENTS.md/...) into the build for provenance
use Moose;
use Path::Tiny;
use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::FileGatherer';

our $VERSION = '0.001';

=head1 DESCRIPTION

Gathers a distribution's B<agent context> from disk into the build under
C<misc/agent-context/> (present in the tarball, but not installed), so that a
built distribution records which skills, agents and rules it was built with.

Unlike C<[Git::GatherDir]> this plugin reads from the working directory, not
from git, so it also captures skilletor-installed (git-ignored) skills, agents
and rules — exactly the content that is not committed in the repository.

=cut

# Per-harness default sets, used when neither `dir` nor `file` is given.
my %HARNESS = (
  claude => { dir => ['.claude'],                  file => ['CLAUDE.md'] },
  codex  => { dir => ['.codex', '.agents/skills'], file => ['AGENTS.md'] },
);
my @HARNESS_ORDER = qw(claude codex);

=attr harness

Which harness default sets to snapshot: C<claude>, C<codex> (repeatable), or
C<all>. Unset means all. Ignored once C<dir>/C<file> are set explicitly.

=attr dir

Directories (repo-relative) to snapshot recursively. Overrides the
harness-derived directory defaults.

=attr file

Single repo-relative files to snapshot. Overrides the harness-derived file
defaults.

=attr to

Base path inside the build. Default C<misc/agent-context>.

=attr exclude_match

Additional exclude regexes (repeatable), applied on top of the built-in ones.

=attr prune_gitignore

Skip C<.gitignore> files (skilletor's per-skill management marker). Default 1.

=attr missing_ok

Silently skip a configured dir/file that is absent. Default 1. Set to 0 to make
an absent configured path fatal.

=cut

has harness         => (is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub { [] });
has dir             => (is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub { [] });
has file            => (is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub { [] });
has to              => (is => 'ro', isa => 'Str',           default => 'misc/agent-context');
has exclude_match   => (is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub { [] });
has prune_gitignore => (is => 'ro', isa => 'Bool',          default => 1);
has missing_ok      => (is => 'ro', isa => 'Bool',          default => 1);

sub mvp_multivalue_args { qw(harness dir file exclude_match) }

sub gather_files { }   # implemented in Task 2

__PACKAGE__->meta->make_immutable;
no Moose;
1;
