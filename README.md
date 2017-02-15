MCMC DB jwa 01/2014
===================

Schema
------

DB is organised into tables:
   - MODEL: model names and specific parameters
   - EXPERIMENT: location, description and parameters of data files
   - RUN: priors, model and data pertaining to a set of MCMC runs
   - TASK: MCMC run on a cell, RUNS are subdivided into TASKS
   - MICROSCOPE: microscope names
   - USER: user names
   - LOG: log output from MCMC runs

Possible future tables:
   - CELL_LINE: cell line descriptions, e.g. HeLa-J WT
   - CONDITION: treatments, e.g. nocadozale x mM

Usage
-----

- As always, try 'help command' for more info.

- Before any use must execute:
  - dbInit

- Query database with:
  - dbShowUsers
  - dbShowMicroscopes
  - dbShowModels
  - dbShowExperiments
  - dbShowTasks

- To import data already in trajData format, use:
  - dbAddExperiment(initials,microscope,file,date,cell_line,name,desc);

- To import data in KiT format, use:
  - dbImportKitData(directory);
  - Several optional arguments are possible, if not supplied they will be queried

- Setup a set of MCMC runs with:
  - dbSetupRuns('name','myrun1');
  - All parameters are optional and will be queried if needed, except name.
  - Priors can be specified as a struct or a string, e.g.:
    - p.L = [10 0.5]; p.kappa = [0.5 1]; ...., or
    - p = 'L=[10 0.5];kappa=[0.5 1];'

- Start executing runs with:
  - dbExecute for multi-core serial execution, or
  - dbExecute('batch') for single-core per task parallel batch execution.

- Check convergence diagnostics:
  - convReport = dbConvergence(run_id);

- Rerun MCMCs to improve convergence with:
  - dbRerun(run_id);

- To compute marginal likelihoods for a run:
  - dbChen(run_id);
  - dbChib(run_id);
