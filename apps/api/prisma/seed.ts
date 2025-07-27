import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...');

  // Create subscription plans
  console.log('📋 Creating subscription plans...');

  // Clear existing plans first
  await prisma.subscriptionPlan.deleteMany({});

  const freePlan = await prisma.subscriptionPlan.create({
    data: {
      name: 'Free',
      description: 'Perfect for getting started',
      priceMonthly: 0,
      priceYearly: 0,
      features: [
        'Up to 3 users',
        'Basic project management',
        'Community support',
        '1GB storage',
      ],
      limits: {
        users: 3,
        projects: 5,
        storage: '1GB',
        apiCalls: 1000,
      },
      isActive: true,
    },
  });

  const proPlan = await prisma.subscriptionPlan.create({
    data: {
      name: 'Professional',
      description: 'For growing teams and businesses',
      priceMonthly: 29.99,
      priceYearly: 299.99,
      features: [
        'Up to 25 users',
        'Advanced project management',
        'Priority support',
        '100GB storage',
        'API access',
        'Custom integrations',
      ],
      limits: {
        users: 25,
        projects: 100,
        storage: '100GB',
        apiCalls: 50000,
      },
      isActive: true,
    },
  });

  const enterprisePlan = await prisma.subscriptionPlan.create({
    data: {
      name: 'Enterprise',
      description: 'For large organizations with advanced needs',
      priceMonthly: 99.99,
      priceYearly: 999.99,
      features: [
        'Unlimited users',
        'Enterprise project management',
        'Dedicated support',
        'Unlimited storage',
        'Full API access',
        'Custom integrations',
        'SSO support',
        'Advanced analytics',
      ],
      limits: {
        users: -1, // unlimited
        projects: -1, // unlimited
        storage: 'unlimited',
        apiCalls: -1, // unlimited
      },
      isActive: true,
    },
  });

  console.log('✅ Subscription plans created');

  // Create demo user (this would normally be created via Supabase Auth)
  console.log('👤 Creating demo user...');

  // Clear existing demo data first
  await prisma.user.deleteMany({ where: { email: 'demo@saas-factory.com' } });

  const demoUser = await prisma.user.create({
    data: {
      id: '00000000-0000-0000-0000-000000000001', // Demo UUID
      email: 'demo@saas-factory.com',
      firstName: 'Demo',
      lastName: 'User',
      emailVerified: true,
      lastLoginAt: new Date(),
    },
  });

  // Create demo organization
  console.log('🏢 Creating demo organization...');

  await prisma.organization.deleteMany({ where: { slug: 'demo-org' } });

  const demoOrg = await prisma.organization.create({
    data: {
      name: 'Demo Organization',
      slug: 'demo-org',
      domain: 'demo.saas-factory.com',
      settings: {
        theme: 'light',
        notifications: true,
        timezone: 'UTC',
      },
      status: 'active',
      createdBy: demoUser.id,
      planId: proPlan.id,
    },
  });

  // Add demo user as organization admin
  console.log('👥 Creating organization membership...');

  await prisma.organizationMember.create({
    data: {
      organizationId: demoOrg.id,
      userId: demoUser.id,
      role: 'admin',
      permissions: ['read', 'write', 'admin'],
      joinedAt: new Date(),
      status: 'active',
    },
  });

  // Create demo subscription
  console.log('💳 Creating demo subscription...');

  await prisma.subscription.create({
    data: {
      organizationId: demoOrg.id,
      planId: proPlan.id,
      status: 'active',
      currentPeriodStart: new Date(),
      currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
      trialStart: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
      trialEnd: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
    },
  });

  // Create demo projects
  console.log('📁 Creating demo projects...');

  const project1 = await prisma.project.create({
    data: {
      organizationId: demoOrg.id,
      name: 'Website Redesign',
      description: 'Complete redesign of the company website with modern UI/UX',
      status: 'active',
      settings: {
        priority: 'high',
        category: 'design',
      },
      createdBy: demoUser.id,
    },
  });

  const project2 = await prisma.project.create({
    data: {
      organizationId: demoOrg.id,
      name: 'Mobile App Development',
      description: 'Native mobile application for iOS and Android',
      status: 'active',
      settings: {
        priority: 'medium',
        category: 'development',
      },
      createdBy: demoUser.id,
    },
  });

  // Create demo tasks
  console.log('✅ Creating demo tasks...');

  await prisma.task.createMany({
    data: [
      {
        organizationId: demoOrg.id,
        projectId: project1.id,
        title: 'Create wireframes',
        description: 'Design wireframes for all main pages',
        status: 'completed',
        priority: 'high',
        assignedTo: demoUser.id,
        createdBy: demoUser.id,
        completedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
      },
      {
        organizationId: demoOrg.id,
        projectId: project1.id,
        title: 'Design homepage mockup',
        description: 'Create high-fidelity mockup for the homepage',
        status: 'in_progress',
        priority: 'high',
        assignedTo: demoUser.id,
        createdBy: demoUser.id,
        dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
      },
      {
        organizationId: demoOrg.id,
        projectId: project2.id,
        title: 'Setup development environment',
        description: 'Configure React Native development environment',
        status: 'todo',
        priority: 'medium',
        assignedTo: demoUser.id,
        createdBy: demoUser.id,
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
      },
    ],
  });

  console.log('🎉 Database seed completed successfully!');
  console.log(`
📊 Summary:
- Created ${await prisma.subscriptionPlan.count()} subscription plans
- Created ${await prisma.user.count()} users
- Created ${await prisma.organization.count()} organizations
- Created ${await prisma.project.count()} projects
- Created ${await prisma.task.count()} tasks
  `);
}

main()
  .catch(e => {
    console.error('❌ Error during seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
