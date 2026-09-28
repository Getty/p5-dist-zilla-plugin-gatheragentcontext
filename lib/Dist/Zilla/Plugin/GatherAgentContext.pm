package Dist::Zilla::Plugin::GatherAgentContext;
# ABSTRACT: Snapshot the agent context (.claude/.codex/CLAUDE.md/AGENTS.md/...) into the build for provenance
use Moose;
use Path::Tiny;
use Encode ();
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

sub _selected_harness {
  my ($self) = @_;
  my @h = @{ $self->harness };
  return @HARNESS_ORDER if !@h || grep { $_ eq 'all' } @h;
  for my $h (@h) {
    $self->log_fatal("unknown harness '$h' (known: @HARNESS_ORDER, all)")
      unless $HARNESS{$h};
  }
  return @h;
}

sub _dirs {
  my ($self) = @_;
  return @{ $self->dir } if @{ $self->dir };
  my (%seen, @dirs);
  for my $h ($self->_selected_harness) {
    push @dirs, grep { !$seen{$_}++ } @{ $HARNESS{$h}{dir} };
  }
  return @dirs;
}

sub _files {
  my ($self) = @_;
  return @{ $self->file } if @{ $self->file };
  my (%seen, @files);
  for my $h ($self->_selected_harness) {
    push @files, grep { !$seen{$_}++ } @{ $HARNESS{$h}{file} };
  }
  return @files;
}

sub _exclude_res {
  my ($self) = @_;
  my @res = (
    qr{(?:^|/)[^/]+\.local\.json$},   # settings.local.json, skilletor.local.json (config)
    qr{(?:^|/)settings\.json$},       # editor/permission config, not agent content
    qr{(?:^|/)worktrees/},
    qr{(?:^|/)\.DS_Store$},
  );
  push @res, qr{(?:^|/)\.gitignore$} if $self->prune_gitignore;
  push @res, map { qr/$_/ } @{ $self->exclude_match };
  return @res;
}

sub _excluded {
  my ($self, $relpath) = @_;
  for my $re ($self->_exclude_res) { return 1 if $relpath =~ $re }
  return 0;
}

sub _snapshot {
  my ($self, $src, $base) = @_;
  my $rel = $src->relative($base);
  return if $self->_excluded("$rel");
  # Strict UTF-8 decode: a binary/non-UTF-8 file must fail loud, not be
  # silently substituted (the lenient :encoding(UTF-8) layer would replace).
  my $content = eval { Encode::decode('UTF-8', $src->slurp_raw, Encode::FB_CROAK) };
  $self->log_fatal(
    "agent-context file '$rel' is not valid UTF-8 (binary content not supported)")
    unless defined $content;
  $self->add_file(Dist::Zilla::File::InMemory->new(
    name    => $self->to . "/$rel",
    content => $content,
  ));
  $self->log_debug("gathered @{[$self->to]}/$rel");
}

sub gather_files {
  my ($self) = @_;
  my $base = path($self->zilla->root)->absolute;

  for my $reldir ($self->_dirs) {
    $self->log_fatal("agent-context path '$reldir' must be relative")
      if path($reldir)->is_absolute;
    my $dir = $base->child($reldir);
    unless ($dir->is_dir) {
      $self->log_fatal("agent-context dir '$reldir' not found under @{[$self->zilla->root]}")
        unless $self->missing_ok;
      next;
    }
    my $iter = $dir->iterator({ recurse => 1, follow_symlinks => 0 });
    while (my $f = $iter->()) {
      next unless $f->is_file;
      next if -l $f;                 # do not snapshot symlinked files
      $self->_snapshot($f, $base);
    }
  }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
