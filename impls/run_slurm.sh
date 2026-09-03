#!/bin/bash
#SBATCH --job-name=saw_subgoal_sweep
#SBATCH --output=logs/saw_subgoal_sweep_%A_%a.out
#SBATCH --error=logs/saw_subgoal_sweep_%A_%a.err
#SBATCH --array=0-139
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=10
#SBATCH --gres=gpu:volta:1
#SBATCH --constraint=volta32gb

unset SLURM_CPU_BIND

SEEDS=(3917 3502 8948 9460 4729 2226 1744 7742 4501 6341)

ENVS=(
    "humanoid-large-navigate-v0"
    "humanoid-giant-navigate-v0"
)

SUBGOAL_STEPS=(2 5 10 25 50 100 250)

NUM_ENVS=${#ENVS[@]}
NUM_SUBGOAL_STEPS=${#SUBGOAL_STEPS[@]}

SUBGOAL_IDX=$((SLURM_ARRAY_TASK_ID % NUM_SUBGOAL_STEPS))
ENV_IDX=$(((SLURM_ARRAY_TASK_ID / NUM_SUBGOAL_STEPS) % NUM_ENVS))
SEED_IDX=$((SLURM_ARRAY_TASK_ID / (NUM_SUBGOAL_STEPS * NUM_ENVS)))

SEED=${SEEDS[$SEED_IDX]}
ENV=${ENVS[$ENV_IDX]}
KL_ALPHA=${KL_ALPHAS[$ENV_IDX]}
SUBGOAL_STEP=${SUBGOAL_STEPS[$SUBGOAL_IDX]}

source .venv/bin/activate

srun python main.py \
    --env_name="$ENV" \
    --eval_episodes=50 \
    --agent=agents/saw.py \
    --agent.subgoal_steps="$SUBGOAL_STEP" \
    --seed="$SEED" \
    --run_group="saw_subgoal_sweep"