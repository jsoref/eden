#chg-compatible

  $ setconfig extensions.treemanifest=!
  $ hg init repo
  $ cd repo
  $ echo foo > foo
  $ hg ci -qAm 'add foo'
  $ echo >> foo
  $ hg ci -m 'change foo'
  $ hg up -qC 0
  $ echo bar > bar
  $ hg ci -qAm 'add bar'

  $ hg log
  changeset:   2:effea6de0384
  parent:      0:bbd179dfa0a7
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     add bar
  
  changeset:   1:ed1b79f46b9a
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     change foo
  
  changeset:   0:bbd179dfa0a7
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     add foo
  
  $ cd ..

don't show "(+1 heads)" message when pulling closed head

  $ hg clone -q repo repo2
  $ hg clone -q repo2 repo3
  $ cd repo2
  $ hg up -q 0
  $ echo hello >> foo
  $ hg ci -mx1
  $ hg ci -mx2 --config ui.allowemptycommit=1
  $ cd ../repo3
  $ hg heads -q --closed
  2:effea6de0384
  1:ed1b79f46b9a
  $ hg pull
  pulling from $TESTTMP/repo2
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 1 changes to 1 files
  new changesets 8c900227dd5d:1a1aa123db21
  $ hg heads -q --closed
  4:1a1aa123db21
  2:effea6de0384
  1:ed1b79f46b9a

  $ cd ..

  $ hg init copy
  $ cd copy

Pull a missing revision:

  $ hg pull -qr missing ../repo
  abort: unknown revision 'missing'!
  (if missing is a remote bookmark or commit, try to 'hg pull' it first)
  [255]

Pull multiple revisions with update:

  $ hg pull -qu -r 0 -r 1 ../repo
  $ hg -q parents
  0:bbd179dfa0a7
  $ hg rollback
  repository tip rolled back to revision -1 (undo pull)
  working directory now based on revision -1

  $ hg pull -qr 0 ../repo
  $ hg log
  changeset:   0:bbd179dfa0a7
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     add foo
  
  $ hg pull -qr 1 ../repo
  $ hg log
  changeset:   1:ed1b79f46b9a
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     change foo
  
  changeset:   0:bbd179dfa0a7
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     add foo
  

This used to abort: received changelog group is empty:

  $ hg pull -qr 1 ../repo

Test race condition with -r and -U (issue4707)

We pull '-U -r <name>' and the name change right after/during the changegroup emission.
We use http because http is better is our racy-est option.


  $ echo babar > ../repo/jungle
  $ cat <<EOF > ../repo/.hg/hgrc
  > [hooks]
  > outgoing.makecommit = hg ci -Am 'racy commit'; echo committed in pull-race
  > EOF
  $ hg serve -R ../repo -p 0 --port-file $TESTTMP/.port -d --pid-file=../repo.pid
  $ HGPORT2=`cat $TESTTMP/.port`
  $ cat ../repo.pid >> $DAEMON_PIDS
  $ hg pull --rev default --update http://localhost:$HGPORT2/
  pulling from http://localhost:$HGPORT2/ (glob)
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  new changesets effea6de0384
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg log -G
  @  changeset:   2:effea6de0384
  |  parent:      0:bbd179dfa0a7
  |  user:        test
  |  date:        Thu Jan 01 00:00:00 1970 +0000
  |  summary:     add bar
  |
  | o  changeset:   1:ed1b79f46b9a
  |/   user:        test
  |    date:        Thu Jan 01 00:00:00 1970 +0000
  |    summary:     change foo
  |
  o  changeset:   0:bbd179dfa0a7
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     add foo
  

  $ cd ..
