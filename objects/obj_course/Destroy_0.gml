// obj_course Destroy - close the lesson editor and free a running test's CPU.
if (instance_exists(editor)) with (editor) ed_close(true);
job_drop();
global.code_editor_build_errors = [];
