#!/bin/bash
#SBATCH --job-name=saw
#SBATCH --output=logs/saw_%A_%a.out
#SBATCH --error=logs/saw_%A_%a.err
#SBATCH --array=0-39
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=10
#SBATCH --gres=gpu:volta:1
#SBATCH --constraint=volta32gb
unset SLURM_CPU_BIND

# 1. Define Arrays
SEEDS=(3917 3502 8948 9460 4729 2226 1744 7742 4501 6341)
ENVS=("large" "giant")
AGENTS=("saw" "hiql")

# 2. Map SLURM_ARRAY_TASK_ID (0-39) to Seed, Env and Agent indices
#    Layout: 10 seeds x 2 envs x 2 agents = 40 tasks
AGENT_IDX=$(( SLURM_ARRAY_TASK_ID % 2 ))
ENV_IDX=$(( (SLURM_ARRAY_TASK_ID / 2) % 2 ))
SEED_IDX=$(( SLURM_ARRAY_TASK_ID / 4 ))

SEED=${SEEDS[$SEED_IDX]}
ENV=${ENVS[$ENV_IDX]}
AGENT=${AGENTS[$AGENT_IDX]}

# Activate the project's local venv.
source .venv/bin/activate

# Use a longer discount for the giant environment.
EXTRA_ARGS=""
if [ "$ENV" == "giant" ]; then
    EXTRA_ARGS="--agent.discount=0.995"
fi

# hiql-specific hyperparameters.
if [ "$AGENT" == "hiql" ]; then
    EXTRA_ARGS="$EXTRA_ARGS --agent.high_alpha=3.0 --agent.low_alpha=3.0"
fi

# 3. Run a single clean srun step
srun python main.py \
    --env_name=antmaze-${ENV}-navigate-v0 \
    --eval_episodes=50 \
    --agent=agents/${AGENT}.py \
    --seed="$SEED" \
    $EXTRA_ARGS
