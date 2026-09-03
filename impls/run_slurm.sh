#!/bin/bash
#SBATCH --job-name=test_metrics
#SBATCH --output=logs/test_metrics_%A_%a.out
#SBATCH --error=logs/test_metrics_%A_%a.err
#SBATCH --array=0-79
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=10
#SBATCH --gres=gpu:volta:1
#SBATCH --constraint=volta32gb

unset SLURM_CPU_BIND

SEEDS=(3917 3502 8948 9460 4729 2226 1744 7742 4501 6341)
ALGOS=("hiql" "saw")
ENVS=(
    "antmaze-giant-navigate-v0"
    "antmaze-large-navigate-v0"
    "cube-single-play-v0"
    "cube-double-play-v0"
)

NUM_ALGOS=${#ALGOS[@]}
NUM_ENVS=${#ENVS[@]}
ALGO_IDX=$((SLURM_ARRAY_TASK_ID % NUM_ALGOS))
ENV_IDX=$(((SLURM_ARRAY_TASK_ID / NUM_ALGOS) % NUM_ENVS))
SEED_IDX=$((SLURM_ARRAY_TASK_ID / (NUM_ALGOS * NUM_ENVS)))

SEED=${SEEDS[$SEED_IDX]}
ALGO=${ALGOS[$ALGO_IDX]}
ENV=${ENVS[$ENV_IDX]}

source .venv/bin/activate

EXTRA_ARGS=()

case "$ENV" in
    cube-single-play-v0)
        EXTRA_ARGS+=(--agent.subgoal_steps=10)
        if [ "$ALGO" = "saw" ]; then
            EXTRA_ARGS+=(--agent.kl_alpha=0.3)
        fi
        ;;
    cube-double-play-v0)
        EXTRA_ARGS+=(--agent.subgoal_steps=10)
        if [ "$ALGO" = "saw" ]; then
            EXTRA_ARGS+=(--agent.kl_alpha=1.0)
        fi
        ;;
esac

srun python main.py \
    --env_name="$ENV" \
    --eval_episodes=50 \
    --agent="agents/${ALGO}.py" \
    --seed="$SEED" \
    --run_group="${ALGO}_test_metrics" \
    "${EXTRA_ARGS[@]}"
