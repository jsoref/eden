#require p4

  $ echo "[extensions]" >> $HGRCPATH
  $ echo "p4fastimport= " >> $HGRCPATH

create p4 depot
  $ p4wd=`pwd`/p4
  $ hgwd=`pwd`/hg
  $ P4ROOT=`pwd`/depot; export P4ROOT
  $ P4AUDIT=$P4ROOT/audit; export P4AUDIT
  $ P4JOURNAL=$P4ROOT/journal; export P4JOURNAL
  $ P4LOG=$P4ROOT/log; export P4LOG
  $ P4PORT=localhost:$HGPORT; export P4PORT
  $ P4DEBUG=1; export P4DEBUG

  $ mkdir $hgwd
  $ mkdir $p4wd
  $ cd $p4wd

start the p4 server
  $ [ ! -d $P4ROOT ] && mkdir $P4ROOT
  $ p4d -C1 -f -J off >$P4ROOT/stdout 2>$P4ROOT/stderr &
  $ echo $! >> $DAEMON_PIDS
  $ trap "echo stopping the p4 server ; p4 admin stop" EXIT

  $ # wait for the server to initialize
  $ while ! p4 ; do
  >    sleep 1
  > done >/dev/null 2>/dev/null

create a client spec
  $ cd $p4wd
  $ P4CLIENT=hg-p4-import; export P4CLIENT
  $ DEPOTPATH=//depot/...
  $ p4 client -o | sed '/^View:/,$ d' >p4client
  $ echo View: >>p4client
  $ echo " $DEPOTPATH //$P4CLIENT/..." >>p4client
  $ p4 client -i <p4client
  Client hg-p4-import saved.

populate the depot
  $ mkdir Main
  $ mkdir Main/b
  $ echo a > Main/a
  $ echo c > Main/b/c
  $ echo d > Main/d
  $ p4 add Main/a Main/b/c Main/d
  //depot/Main/a#1 - opened for add
  //depot/Main/b/c#1 - opened for add
  //depot/Main/d#1 - opened for add
  $ p4 submit -d initial
  Submitting change 1.
  Locking 3 files ...
  add //depot/Main/a#1
  add //depot/Main/b/c#1
  add //depot/Main/d#1
  Change 1 submitted.

  $ p4 edit Main/a Main/b/c Main/d
  //depot/Main/a#1 - opened for edit
  //depot/Main/b/c#1 - opened for edit
  //depot/Main/d#1 - opened for edit
  $ echo a >> Main/a
  $ echo c >> Main/b/c
  $ echo d >> Main/d
  $ p4 submit -d second
  Submitting change 2.
  Locking 3 files ...
  edit //depot/Main/a#2
  edit //depot/Main/b/c#2
  edit //depot/Main/d#2
  Change 2 submitted.

Simple import

  $ cd $hgwd
  $ hg init --config 'format.usefncache=False'
  $ hg p4fastimport --debug -P $P4ROOT hg-p4-import
  loading changelist numbers.
  2 changelists to import.
  loading list of files.
  3 files to import.
  importing repository.
  writing filelog: b789fdd96dc2, p1 000000000000, linkrev 0, 2 bytes, src: *, path: depot/Main/a (glob)
  writing filelog: a80d06849b33, p1 b789fdd96dc2, linkrev 1, 4 bytes, src: *, path: depot/Main/a (glob)
  writing filelog: 149da44f2a4e, p1 000000000000, linkrev 0, 2 bytes, src: *, path: depot/Main/b/c (glob)
  writing filelog: b11e10a88bfa, p1 149da44f2a4e, linkrev 1, 4 bytes, src: *, path: depot/Main/b/c (glob)
  writing filelog: a9092a3d84a3, p1 000000000000, linkrev 0, 2 bytes, src: *, path: depot/Main/d (glob)
  writing filelog: f83f0637e55e, p1 a9092a3d84a3, linkrev 1, 4 bytes, src: *, path: depot/Main/d (glob)
  changelist 1: writing manifest. node: 17971aea5e86 p1: 000000000000 p2: 000000000000 linkrev: 0
  changelist 1: writing changelog: initial
  changelist 2: writing manifest. node: ee5866cdbad7 p1: 17971aea5e86 p2: 000000000000 linkrev: 1
  changelist 2: writing changelog: second
  2 revision(s), 3 file(s) imported.

Additional Edit

  $ cd $p4wd
  $ p4 edit Main/a Main/b/c
  //depot/Main/a#2 - opened for edit
  //depot/Main/b/c#2 - opened for edit
  $ echo a >> Main/a
  $ echo c >> Main/b/c
  $ p4 submit -d third
  Submitting change 3.
  Locking 2 files ...
  edit //depot/Main/a#3
  edit //depot/Main/b/c#3
  Change 3 submitted.

  $ p4 edit Main/a
  //depot/Main/a#3 - opened for edit
  $ echo a >> Main/a
  $ p4 submit -d fourth
  Submitting change 4.
  Locking 1 files ...
  edit //depot/Main/a#4
  Change 4 submitted.

Incremental import

  $ cd $hgwd
  $ hg p4fastimport --debug -P $P4ROOT hg-p4-import
  incremental import from changelist: 3, node: * (glob)
  loading changelist numbers.
  2 changelists to import.
  loading list of files.
  2 files to import.
  importing repository.
  writing filelog: 544ee3484b75, p1 a80d06849b33, linkrev 2, 6 bytes, src: *, path: depot/Main/a (glob)
  writing filelog: c96a7bc5f25b, p1 544ee3484b75, linkrev 3, 8 bytes, src: *, path: depot/Main/a (glob)
  writing filelog: b7282976f1b3, p1 b11e10a88bfa, linkrev 2, 6 bytes, src: *, path: depot/Main/b/c (glob)
  changelist 3: writing manifest. node: 7357c6fa87bd p1: ee5866cdbad7 p2: 000000000000 linkrev: 2
  changelist 3: writing changelog: third
  changelist 4: writing manifest. node: a08ce793cc8b p1: 7357c6fa87bd p2: 000000000000 linkrev: 3
  changelist 4: writing changelog: fourth
  2 revision(s), 2 file(s) imported.

Verify

  $ hg verify
  checking changesets
  checking manifests
  crosschecking files in changesets and manifests
  checking files
  3 files, 4 changesets, 9 total revisions

  stopping the p4 server
