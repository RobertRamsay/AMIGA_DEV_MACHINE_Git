global.tour_settling = false;

// Never leave the demo in place of the user's workspace.
if (tour_stash != undefined) {
    var _stash = tour_stash;
    tour_stash = undefined;
    scr_tour_restore_workspace(_stash);
}
